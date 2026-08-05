import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:errand/config/supabase_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  Map<String, dynamic>? userData;
  File? _image;

  String _profilePhotoUrl() {
    final photoUrl = userData?['profilePhoto']?.toString() ?? '';
    if (photoUrl.isEmpty) return '';
    if (photoUrl.contains('<') || photoUrl.contains('YOUR_PROJECT_ID')) {
      return '';
    }

    final version = userData?['profilePhotoUpdatedAt'];
    if (version == null) return photoUrl;

    final versionValue =
        version is Timestamp
            ? version.millisecondsSinceEpoch
            : version.toString();
    final separator = photoUrl.contains('?') ? '&' : '?';

    return '$photoUrl${separator}v=$versionValue';
  }

  ImageProvider<Object>? _profileImageProvider() {
    if (_image != null) return FileImage(_image!);

    final photoUrl = _profilePhotoUrl();
    if (photoUrl.isNotEmpty) return NetworkImage(photoUrl);

    return null;
  }

  String _profileInitial() {
    final name = userData?['name']?.toString().trim() ?? '';
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  Color _profileAvatarColor() {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFFDC2626),
      Color(0xFFEA580C),
      Color(0xFF059669),
      Color(0xFF0891B2),
    ];
    final name = userData?['name']?.toString().trim() ?? '';
    final seed = name.isEmpty ? (user?.uid ?? '?') : name;
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return colors[hash % colors.length];
  }

  Widget _profileAvatar() {
    final imageProvider = _profileImageProvider();
    return CircleAvatar(
      radius: 50,
      backgroundColor: _profileAvatarColor(),
      backgroundImage: imageProvider,
      child:
          imageProvider == null
              ? Text(
                _profileInitial(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
    );
  }

  String _networkErrorMessage(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return 'Network error. Check your internet connection and try again.';
    }

    return 'Error uploading image: $error';
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        if (!mounted) return;
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not load profile. Check your connection and try again.',
            ),
          ),
        );
        setState(() {
          userData = {};
        });
      }
    }
  }

  Future<void> _updateUserData(String key, String newValue) async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).update({
        key: newValue,
      });
      setState(() {
        userData![key] = newValue;
      });
    }
  }

  Future<void> _editField(String key, String currentValue) async {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit $key"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "Enter new $key"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _updateUserData(key, controller.text);
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });

      try {
        final userId = user!.uid;
        final updatedAt = DateTime.now().millisecondsSinceEpoch;
        final fileName = "$userId-$updatedAt.jpg";
        final bytes = await imageFile.readAsBytes();
        debugPrint('KEY LENGTH: ${supabaseKey.length}');

        final response = await http
            .post(
              Uri.parse('$supabaseUrl/storage/v1/object/$supabaseUserProfileBucket/$fileName'),
              headers: {
                'Authorization': 'Bearer $supabaseKey',
                'apikey': supabaseKey,
                'Content-Type': 'application/octet-stream',
                'x-upsert': 'true',
              },
              body: bytes,
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final publicUrl =
              '$supabaseUrl/storage/v1/object/public/$supabaseUserProfileBucket/$fileName';

          await _firestore.collection('users').doc(userId).update({
            'profilePhoto': publicUrl,
            'profilePhotoUpdatedAt': updatedAt,
          });

          if (!mounted) return;
          setState(() {
            userData!['profilePhoto'] = publicUrl;
            userData!['profilePhotoUpdatedAt'] = updatedAt;
          });
        } else {
          debugPrint('Upload failed: ${response.body}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.body}')),
          );
        }
      } catch (e) {
        debugPrint("Error uploading image: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_networkErrorMessage(e))));
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).delete();
      await user!.delete();
      _auth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body:
          userData == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _profileAvatar(),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text(
                        'Change Profile Photo',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 20),
                    buildSectionTitle('Profile Information'),
                    buildInfoTile(
                      Iconsax.user,
                      'Name',
                      userData!['name'] ?? 'N/A',
                      'name',
                    ),
                    buildInfoTile(
                      Iconsax.profile_circle,
                      'Username',
                      userData!['username'] ?? 'N/A',
                      'username',
                    ),
                    SizedBox(height: 10),
                    buildSectionTitle('Personal Information'),
                    buildInfoTile(
                      Iconsax.card,
                      'Student ID',
                      userData!['studentId'] ?? 'N/A',
                      'studentId',
                    ),
                    buildInfoTile(
                      Iconsax.sms,
                      'Email',
                      userData!['email'] ?? 'N/A',
                      'email',
                    ),
                    buildInfoTile(
                      Iconsax.call,
                      'Phone Number',
                      userData!['phone'] ?? 'N/A',
                      'phone',
                    ),
                    buildInfoTile(
                      Iconsax.user_octagon,
                      'Gender',
                      userData!['gender'] ?? 'N/A',
                      'gender',
                    ),
                    buildInfoTile(
                      Iconsax.home,
                      'Room Number',
                      userData!['roomNumber'] ?? 'N/A',
                      'roomNumber',
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text("Delete Account"),
                                content: Text(
                                  "Are you sure you want to delete your account? This action cannot be undone.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: _deleteAccount,
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildInfoTile(IconData icon, String title, String value, String key) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(value, style: TextStyle(color: Colors.black87)),
      onTap: () => _editField(key, value),
    );
  }
}
