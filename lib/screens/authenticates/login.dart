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
  final _formKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthServices _authServices = AuthServices();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _showLoginForm = false;
  bool _showSignUpForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserModel? user;
      if (_isLogin) {
        user = await _authServices.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        user = await _authServices.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (user != null && mounted) {
        showSuccessDialog(
          context,
          _isLogin ? 'Successfully logged in!' : 'Account created successfully!',
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        showErrorDialog(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserModel? user = await _authServices.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        showSuccessDialog(context, 'Account created successfully!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        showErrorDialog(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authServices.signInWithGoogle();
      if (user != null && mounted) {
        showSuccessDialog(context, 'Successfully logged in with Google!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        showErrorDialog(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.5, -0.8),
            end: Alignment(0.5, 0.8),
            colors: [
              Color(0xFF000000),
              Color(0xFF1E1E1E),
              Color(0xFF232323),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _showLoginForm
            ? _buildLoginForm()
            : _showSignUpForm
                ? _buildSignUpForm()
                : _buildInitialScreen(),
      ),
    );
  }

  Widget _buildInitialScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 85),

              // App logo
              Center(
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    image: const DecorationImage(
                      image: AssetImage('assets/logos/app-logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 120),

              // Sign Up Button
              SizedBox(
                width: 303,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isLogin = false;
                      _showSignUpForm = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: 303,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isLogin = true;
                      _showLoginForm = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // OR CONTINUE WITH with responsive dividers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 1,
                        endIndent: 10,
                      ),
                    ),
                    Text(
                      'OR CONTINUE WITH',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 1,
                        indent: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Google Sign In Button
              Center(
                child: InkWell(
                  onTap: _isLoading ? null : _googleSignIn,
                  child: Container(
                    width: 150,
                    height: 31.17,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Google',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 20),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    side: const BorderSide(width: 4, color: Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      _showLoginForm = false;
                    });
                  },
                ),
              ),

              // Login title
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // Username field
              Center(
                child: Container(
                  width: 280,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      hintText: 'Username',
                      hintStyle: GoogleFonts.poppins(),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 21),

              // Password field
              Center(
                child: Container(
                  width: 280,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      hintText: 'Password',
                      hintStyle: GoogleFonts.poppins(),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 21),

              // Forgot your user name or password?
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: SizedBox(
                  width: 222,
                  height: 18,
                  child: Text(
                    'Forgot your user name or password?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                      color: const Color(0xFFD8D8D8).withOpacity(0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Login button
              Center(
                child: Container(
                  width: 113,
                  height: 39,
                  decoration: BoxDecoration(
                    color: const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFFE8E8E8))
                        : Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE8E8E8),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _signUpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 20),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    side: const BorderSide(width: 4, color: Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      _showSignUpForm = false;
                    });
                  },
                ),
              ),

              // Sign Up title
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // Email field
              Center(
                child: Container(
                  width: 280,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      hintText: 'Email',
                      hintStyle: GoogleFonts.poppins(),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 21),

              // Password field
              Center(
                child: Container(
                  width: 280,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      hintText: 'Password',
                      hintStyle: GoogleFonts.poppins(),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 21),

              // Confirm Password field
              Center(
                child: Container(
                  width: 280,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      hintText: 'Confirm Password',
                      hintStyle: GoogleFonts.poppins(),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Create Account button
              Center(
                child: Container(
                  width: 303,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Already registered?
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showSignUpForm = false;
                      _showLoginForm = true;
                    });
                  },
                  child: Text(
                    'Already registered?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}