import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File handling
import '../../model/user_model.dart';
import '../../services/auth_services.dart'; // For sign out

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  UserModel? _userModel;
  bool _isLoading = true;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  // Controllers for editing profile details
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final userDetails = await UserModel.fetchUserDetails(firebaseUser);
      if (mounted) {
         setState(() {
           _userModel = userDetails;
           _isLoading = false;
           // Initialize controllers with user data
           _fullNameController.text = _userModel?.displayName ?? '';
           _addressController.text = _userModel?.address ?? '';
           _phoneNumberController.text = _userModel?.phoneNumber ?? '';
           _passwordController.text = '••••••••'; // Placeholder for password
         });
      }
    } else {
      print("Error: No Firebase user found in AccountPage.");
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("User not logged in. Redirecting..."), backgroundColor: Colors.red)
         );
         Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
               Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
         });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _signOut() async {
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
           title: const Text('Confirm Sign Out'),
           content: const Text('Are you sure you want to sign out?'),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(context).pop(false),
               child: const Text('Cancel'),
             ),
             TextButton(
               onPressed: () => Navigator.of(context).pop(true),
               child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
             ),
           ],
         ),
      );

    if (confirm == true && mounted) {
       final authServices = AuthServices();
       await authServices.signOut();
       if (mounted) {
         Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
       }
    }
  }

  void _showProfileDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 101,
                  height: 101,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.person, color: Colors.black, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userModel?.displayName ?? '',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileField('Full Name', _fullNameController),
              _buildProfileField('Address', _addressController),
              _buildProfileField('Phone Number', _phoneNumberController),
              _buildProfileField('Password', _passwordController, obscureText: true),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _editProfileDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Change details',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  // Save profile data
                  await _saveProfileData();
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && _userModel != null) {
        // Update user model with new values
        _userModel!.updateFromDisplayName(_fullNameController.text);
        _userModel!.address = _addressController.text;
        _userModel!.phoneNumber = _phoneNumberController.text;
        
        // Save image if changed
        if (_image != null) {
          // Upload image to Firebase Storage and get URL
          // This is a placeholder - implement your image upload functionality
          // String imageUrl = await uploadImageToStorage(_image!, firebaseUser.uid);
          // _userModel!.photoUrl = imageUrl;
        }
        
        // Save updated user data to Firestore
        await _userModel!.saveToFirestore();
        
        // Update display name in Firebase Auth
        await firebaseUser.updateDisplayName(_fullNameController.text);
        
        // Handle password change if needed
        if (_passwordController.text != '••••••••') {
          await firebaseUser.updatePassword(_passwordController.text);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      print("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _editProfileDetails() {
    // This now just informs the user they can edit the fields directly
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Edit your details and click Save to update your profile"),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF232323),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.logout),
             tooltip: 'Sign Out',
             onPressed: _signOut,
           ),
         ],
      ),
      backgroundColor: Colors.white, // Set background color to white
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: Colors.white,
        backgroundColor: Colors.grey[800],
        child: SingleChildScrollView(
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : _userModel == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 50),
                          const SizedBox(height: 16),
                          const Text("Could not load user data.", style: TextStyle(color: Colors.black87)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"),
                            onPressed: _fetchUserData,
                            style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.black),
                          )
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            decoration: BoxDecoration(
                              color: const Color(0xFF232323),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 101,
                                    height: 101,
                                    margin: const EdgeInsets.only(top: 44), // Adjusted position
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _image != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.file(_image!, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.person, color: Colors.black, size: 40),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _userModel!.displayName,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 26,
                                    height: 1.2,
                                    color: const Color(0xFFF9F9F9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start, // Align to the left
                            children: [
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: _showProfileDetails,
                                    child: Container(
                                      width: 89,
                                      height: 89,
                                      margin: const EdgeInsets.only(left: 21), // Adjusted position
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      ),
                                      child: const Icon(Icons.person, color: Colors.black, size: 40),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    margin: const EdgeInsets.only(left: 21),
                                    child: Text(
                                      'Profile',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Add more buttons here if needed
                            ],
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}