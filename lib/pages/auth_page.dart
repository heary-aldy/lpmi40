import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

class AuthPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AuthPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      User? user;
      if (_isSignUp) {
        if (_nameController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Please enter your name';
          });
          return;
        }
        user = await _firebaseService.createUserWithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim());
      } else {
        user = await _firebaseService.signInWithEmailPassword(
            _emailController.text.trim(), _passwordController.text);
      }

      if (user != null && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        setState(() {
          _errorMessage = _isSignUp
              ? 'Failed to create account'
              : 'Invalid email or password';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
    });
  }

  // ✅ FIXED: Proper guest authentication
  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _firebaseService.signInAsGuest();
      if (user != null && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to sign in as guest';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Guest sign-in error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/header_image.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).primaryColor,
                  )),
          Container(color: Colors.black.withOpacity(0.6)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  const SizedBox(height: 40),
                  const Icon(Icons.music_note, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Lagu Pujian Masa Ini',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Sign in to sync your favorites across devices',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 40),

                  // Auth Form Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_isSignUp ? 'Create Account' : 'Sign In',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        if (_isSignUp) ...[
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12))),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red)),
                            child: Row(
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_errorMessage!,
                                        style: const TextStyle(
                                            color: Colors.red))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(_isSignUp ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25))),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text(_isSignUp
                              ? 'Already have an account? Sign In'
                              : 'Don\'t have an account? Sign Up'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Footer Section
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: const Text('Continue as Guest',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                        widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
