import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import 'order_history_page.dart';

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

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
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
           _fullNameController.text = _userModel?.displayName ?? '';
           _addressController.text = _userModel?.address ?? '';
           _phoneNumberController.text = _userModel?.phoneNumber ?? '';
           _passwordController.text = '••••••••';
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),
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
                    border: _image == null ? Border.all(color: Colors.grey, width: 1) : null,
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                      : _userModel?.photoUrl != null && _userModel!.photoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                  _userModel!.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.black, size: 40)
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.black, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userModel?.displayName ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileField('Full Name', _fullNameController, enabled: true),
              _buildProfileField('Address', _addressController, enabled: true),
              _buildProfileField('Phone Number', _phoneNumberController, enabled: true),
              _buildProfileField('Password', _passwordController, obscureText: true, enabled: true),
              const SizedBox(height: 20),
               Text(
                 'Edit the fields above and click "Save" to update.',
                 style: GoogleFonts.poppins(
                   fontWeight: FontWeight.w400,
                   fontStyle: FontStyle.italic,
                   fontSize: 12,
                   color: Colors.black54,
                 ),
                 textAlign: TextAlign.center,
               ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfileData,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, {bool obscureText = false, bool enabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
             enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
             ),
            disabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.black,
          ),
          readOnly: !enabled,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveProfileData() async {
    if (_userModel == null || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _userModel!.updateFromDisplayName(_fullNameController.text.trim());
        _userModel!.address = _addressController.text.trim();
        _userModel!.phoneNumber = _phoneNumberController.text.trim();

        final newPassword = _passwordController.text.trim();
        if (newPassword.isNotEmpty && newPassword != '••••••••') {
           try {
             await firebaseUser.updatePassword(newPassword);
             print("Password updated successfully.");
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password updated successfully."), backgroundColor: Colors.orangeAccent)
                );
             }
           } on FirebaseAuthException catch (e) {
              print("Firebase Auth Error updating password: ${e.code} - ${e.message}");
              String errorMessage = "Failed to update password.";
              if (e.code == 'requires-recent-login') {
                 errorMessage = "Please log out and log in again to update your password.";
              } else if (e.message != null) {
                 errorMessage = "Error updating password: ${e.message}";
              }
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(errorMessage), backgroundColor: Colors.red)
                 );
              }
           } catch (e) {
              print("Unexpected error updating password: $e");
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Unexpected error updating password: ${e.toString()}"), backgroundColor: Colors.red)
                 );
              }
           }
        } else if (newPassword == '••••••••') {
        } else if (newPassword.isEmpty) {
            if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Password cannot be empty if changing."), backgroundColor: Colors.orange)
                 );
              }
        }

        if (_image != null) {
          // Implement image upload logic here
        }

        if (_userModel!.displayName != firebaseUser.displayName) {
             await firebaseUser.updateDisplayName(_userModel!.displayName);
             print("Firebase Auth display name updated.");
        }

        await _userModel!.saveToFirestore();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green)
          );
          _fetchUserData();
          Navigator.pop(context);
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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: Colors.white,
        backgroundColor: Colors.grey[800],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Colors.black),
                  )
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
                                Container(
                                   width: 101,
                                   height: 101,
                                   margin: const EdgeInsets.only(top: 20),
                                   decoration: BoxDecoration(
                                     color: Colors.white,
                                     borderRadius: BorderRadius.circular(10),
                                     border: _userModel?.photoUrl == null && _image == null ? Border.all(color: Colors.grey, width: 1) : null,
                                   ),
                                   child: _image != null
                                       ? ClipRRect(
                                           borderRadius: BorderRadius.circular(10),
                                           child: Image.file(_image!, fit: BoxFit.cover),
                                         )
                                       : (_userModel?.photoUrl != null && _userModel!.photoUrl!.isNotEmpty
                                           ? ClipRRect(
                                               borderRadius: BorderRadius.circular(10),
                                               child: Image.network(
                                                   _userModel!.photoUrl!,
                                                   fit: BoxFit.cover,
                                                   errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.black, size: 40)
                                               ),
                                             )
                                           : const Icon(Icons.person, color: Colors.black, size: 40)
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
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildAccountButton(
                                  icon: Icons.person,
                                  label: 'Profile',
                                  onTap: _showProfileDetails,
                                ),
                                _buildAccountButton(
                                  icon: Icons.history,
                                  label: 'Order History',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
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
            child: Icon(icon, color: Colors.black, size: 35),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
