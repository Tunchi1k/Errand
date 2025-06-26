import 'package:errand/pages/Homepage/home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RunnerVerificationPage extends StatefulWidget {
  const RunnerVerificationPage({super.key});

  @override
  State<RunnerVerificationPage> createState() => _RunnerVerificationPageState();
}

class _RunnerVerificationPageState extends State<RunnerVerificationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _computerNumberController =
      TextEditingController();
  final TextEditingController _nrcController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  File? _nrcPhoto;
  File? _profilePhoto;

  String? fetchedName;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchName();
  }

  void fetchName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        fetchedName = doc['name'];
      });
    }
  }

  Future<void> pickImage(bool isNrc) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isNrc) {
          _nrcPhoto = File(picked.path);
        } else {
          _profilePhoto = File(picked.path);
        }
      });
    }
  }

  Future<String> uploadFileToSupabase(File file, String path) async {
    const bucket = 'verifications';
    const supabaseUrl = 'https://rfqnervrhxzackrmuoec.supabase.co';
    const supabaseKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcW5lcnZyaHh6YWNrcm11b2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxODUyMzAsImV4cCI6MjA2NTc2MTIzMH0.NywMytTREcK2onPcAY53tUDS0tvulCK0eeuRKXMXbNg'; // Replace with your anon/public key

    final uploadUrl = '$supabaseUrl/storage/v1/object/$bucket/$path';
    final bytes = await file.readAsBytes();

    final response = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': 'Bearer $supabaseKey',
        'apikey': supabaseKey,
        'Content-Type': 'application/octet-stream',
      },
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return '$supabaseUrl/storage/v1/object/public/$bucket/$path';
    } else {
      throw Exception(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  void submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nrcPhoto == null || _profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both photos.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final nrcUrl = await uploadFileToSupabase(
        _nrcPhoto!,
        '${user.uid}/nrc.jpg',
      );
      final profileUrl = await uploadFileToSupabase(
        _profilePhoto!,
        '${user.uid}/selfie.jpg',
      );

      await FirebaseFirestore.instance
          .collection('runner_verifications')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'fetched_name': fetchedName,
            'submitted_name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'computer_number': _computerNumberController.text.trim(),
            'nrc': _nrcController.text.trim(),
            'room': _roomController.text.trim(),
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
            'nrc_photo_url': nrcUrl,
            'profile_photo_url': profileUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification submitted. Awaiting admin approval.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: Colors.black) : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildUploadSection(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child:
                file == null
                    ? const Center(child: Text("Tap to upload"))
                    : Image.file(file, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 440,
                    height: 200,
                    child: Image.asset("images/verify.png"),
                  ),
                ),
                const SizedBox(height: 40),
                buildField(
                  label: "Email Address",
                  hint: "Enter email",
                  controller: _emailController,
                  icon: Icons.email,
                  type: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Enter your email";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                      return "Invalid email";
                    return null;
                  },
                ),
                buildField(
                  label: "Name",
                  hint: "Enter full name",
                  controller: _nameController,
                  icon: Icons.person,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Please enter your full name"
                              : null,
                ),
                buildField(
                  label: "Phone Number",
                  hint: "+260",
                  controller: _phoneController,
                  icon: Icons.phone,
                  type: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Enter phone number";
                    if (!RegExp(r'^\d{10}$').hasMatch(value))
                      return "Must be 10 digits";
                    return null;
                  },
                ),
                buildField(
                  label: "Computer Number",
                  hint: "Enter computer number",
                  controller: _computerNumberController,
                  icon: Icons.computer,
                  type: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Enter computer number";
                    if (!RegExp(r'^\d{10}$').hasMatch(value))
                      return "Must be 10 digits";
                    return null;
                  },
                ),
                buildField(
                  label: "NRC Number",
                  hint: "Enter NRC number",
                  controller: _nrcController,
                  icon: Icons.credit_card,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Invalid NRC number";
                    if (!RegExp(r'^\d{6}/\d{2}/\d$').hasMatch(value))
                      return "Invalid NRC format";
                    return null;
                  },
                ),
                buildUploadSection(
                  "Upload NRC Photo",
                  _nrcPhoto,
                  () => pickImage(true),
                ),
                buildUploadSection(
                  "Upload Selfie",
                  _profilePhoto,
                  () => pickImage(false),
                ),
                buildField(
                  label: "Room Number",
                  hint: "Enter room number",
                  controller: _roomController,
                  icon: Icons.home,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Enter room number"
                              : null,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : submitVerification,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child:
                        isSubmitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Submit for Verification",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
