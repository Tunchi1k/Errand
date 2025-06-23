import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>?;
      });
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

      // Upload image to Firebase Storage
      try {
        String filePath = 'profile_photos/${user!.uid}.jpg';
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child(filePath)
            .putFile(imageFile);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with the new profile picture URL
        await _firestore.collection('users').doc(user!.uid).update({
          'profilePhoto': downloadUrl,
        });

        // Update local state
        setState(() {
          userData!['profilePhoto'] = downloadUrl;
        });
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).delete();
      await user!.delete();
      _auth.signOut();
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
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _image != null
                              ? FileImage(_image!)
                              : NetworkImage(userData!['profilePhoto'] ?? '')
                                  as ImageProvider,
                    ),
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
