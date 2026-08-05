import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:errand/config/supabase_config.dart';
import 'package:errand/pages/profile/role_switch.dart';

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
      Color(0xFF111827)
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
    final account = user ?? _auth.currentUser;
    if (account == null) return;

    try {
      await account.delete();
      await _firestore.collection('users').doc(account.uid).delete();
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message =
          e.code == 'requires-recent-login'
              ? 'For your security, please sign in again before deleting your account.'
              : 'Could not delete your account. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete your account. Please try again.')),
      );
    }
  }

  Widget _profileInfoCard() => _infoCard(
    title: 'Profile Information',
    children: [
      buildInfoTile(Iconsax.user, 'Name', userData!['name'] ?? 'N/A', 'name'),
      buildInfoTile(Iconsax.profile_circle, 'Username', userData!['username'] ?? 'N/A', 'username'),
    ],
  );

  Widget _personalInfoCard() => _infoCard(
    title: 'Personal Information',
    children: [
      buildInfoTile(Iconsax.card, 'Student ID', userData!['studentId'] ?? 'N/A', 'studentId'),
      buildInfoTile(Iconsax.sms, 'Email', userData!['email'] ?? 'N/A', 'email'),
      buildInfoTile(Iconsax.call, 'Phone Number', userData!['phone'] ?? 'N/A', 'phone'),
      buildInfoTile(Iconsax.user_octagon, 'Gender', userData!['gender'] ?? 'N/A', 'gender'),
      buildInfoTile(Iconsax.home, 'Room Number', userData!['roomNumber'] ?? 'N/A', 'roomNumber'),
    ],
  );

  Widget _accountDetailsCard() => _infoCard(
    title: 'Account Details',
    children: [
      ListTile(
        leading: const Icon(Icons.badge_outlined),
        title: const Text('Role'),
        subtitle: Text(userData!['role']?.toString() ?? 'Not set'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final currentRole = userData!['role']?.toString() ?? 'Sender';
          final switched = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => RoleSwitchPage(currentRole: currentRole),
            ),
          );
          if (switched == true && mounted) {
            final account = _auth.currentUser;
            if (account != null) {
              final snapshot = await _firestore.collection('users').doc(account.uid).get();
              if (mounted) setState(() => userData = snapshot.data());
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Change Password'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _changePassword,
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        onTap: _confirmDeleteAccount,
      ),
    ],
  );

  Future<void> _switchToRunner() async {
    final account = _auth.currentUser;
    if (account == null) return;
    await _firestore.collection('users').doc(account.uid).update({
      'role': 'Runner',
      'isVerified': false,
    });
    if (!mounted) return;
    setState(() => userData = {...?userData, 'role': 'Runner', 'isVerified': false});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are now a runner. Complete verification to accept errands.')));
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Update')),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.length < 6) return;
    try {
      await _auth.currentUser?.updatePassword(password);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.code == 'requires-recent-login' ? 'Please sign in again before changing your password.' : 'Could not update password.')));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) _deleteAccount();
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0D111827), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [buildSectionTitle(title), ...children],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F4F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF3F4F6),
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
                    _profileInfoCard(),
                    const SizedBox(height: 16),
                    _personalInfoCard(),
                    const SizedBox(height: 16),
                    _accountDetailsCard(),
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
