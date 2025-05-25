import 'package:flutter/material.dart';
import '../../providers/dialog_helper.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController(); // New controller
  final _addressController = TextEditingController(); // New controller

  final AuthServices _authServices = AuthServices();

  bool _isLoading = false;
  bool _showLoginForm = false;
  bool _showSignUpForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose(); // Dispose new controller
    _addressController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _clearControllers() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneNumberController.clear(); // Clear new controller
    _addressController.clear(); // Clear new controller
    _loginFormKey.currentState?.reset();
    _signUpFormKey.currentState?.reset();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _navigateToAdminLogin() {
    if (mounted) {
      Navigator.pushNamed(context, '/adminlogin');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserModel? user = await _authServices.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null && mounted) {
        _showSuccess('Successfully logged in!');
        Future.delayed(const Duration(seconds: 1), _navigateToHome);
      } else if (mounted) {
        _showError('Login failed. Please check credentials.');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      print("Login Error: $e");
      _showError('An unexpected error occurred during login.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserModel? user = await _authServices.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(), // Pass phone number
        address: _addressController.text.trim(), // Pass address
      );
      if (user != null && mounted) {
        _showSuccess('Account created successfully!');
        Future.delayed(const Duration(seconds: 1), _navigateToHome);
      } else if (mounted) {
        _showError('Account creation failed. Please try again.');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      print("Sign Up Error: $e");
      _showError('An unexpected error occurred during sign up.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authServices.signInWithGoogle();
      if (user != null && mounted) {
        _showSuccess('Successfully logged in with Google!');
        Future.delayed(const Duration(seconds: 1), _navigateToHome);
      } else if (mounted && user == null) {
        print("Google Sign In cancelled by user.");
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      print("Google Sign In Error: $e");
      _showError('An unexpected error occurred during Google Sign In.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.5, -0.8), end: Alignment(0.5, 0.8),
            colors: [Color(0xFF000000), Color(0xFF1E1E1E), Color(0xFF232323)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
          child: _showLoginForm
              ? _buildLoginForm()
              : _showSignUpForm
              ? _buildSignUpForm()
              : _buildInitialScreen(),
        ),
      ),
    );
  }

  Widget _buildInitialScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 85, height: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              image: const DecorationImage(
                image: AssetImage('assets/logos/app-logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  _clearControllers();
                  setState(() => _showSignUpForm = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Colors.white, width: 0.5),
                ),
                child: Text('Sign Up', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  _clearControllers();
                  setState(() => _showLoginForm = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Login', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _navigateToAdminLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Colors.white70, width: 0.5),
                  elevation: 0,
                ),
                child: Text('Seller Login', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Colors.white, thickness: 1, endIndent: 10)),
                Text('OR CONTINUE WITH', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white)),
                const Expanded(child: Divider(color: Colors.white, thickness: 1, indent: 10)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          InkWell(
            onTap: _googleSignIn,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata, size: 24, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => setState(() => _showLoginForm = false),
            ),
            const SizedBox(height: 20),
            Center(child: Text('Login', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w500, color: Colors.white))),
            const SizedBox(height: 35),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: true,
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 21),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => _showError("Forgot Password not implemented."),
                  child: Text('Forgot password?', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, decoration: TextDecoration.underline)),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF232323),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('Login', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: InkWell(
                onTap: () {
                  _clearControllers();
                  setState(() {
                    _showLoginForm = false;
                    _showSignUpForm = true;
                  });
                },
                child: Text("Don't have an account? Sign Up", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => setState(() => _showSignUpForm = false),
            ),
            const SizedBox(height: 20),
            Center(child: Text('Sign Up', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w500, color: Colors.white))),
            const SizedBox(height: 35),
            _buildTextField(
              controller: _firstNameController,
              hintText: 'First Name',
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter first name' : null,
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _lastNameController,
              hintText: 'Last Name',
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter last name' : null,
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _phoneNumberController,
              hintText: 'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter phone number' : null,
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _addressController,
              hintText: 'Address',
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter address' : null,
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter password';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 21),
            _buildTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 220,
                height: 44,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('Create Account', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: InkWell(
                onTap: () {
                  _clearControllers();
                  setState(() {
                    _showSignUpForm = false;
                    _showLoginForm = true;
                  });
                },
                child: Text('Already registered? Login', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600], size: 20) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          errorStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.redAccent, height: 0.8),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}