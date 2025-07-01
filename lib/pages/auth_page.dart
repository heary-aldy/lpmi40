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
  final _formKey = GlobalKey<FormState>(); // ✅ Added form validation

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage; // ✅ Added success message

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ✅ IMPROVED: Better validation and error handling
  Future<void> _signInWithEmail() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user;
      if (_isSignUp) {
        debugPrint('🔄 Starting registration process...');
        user = await _firebaseService.createUserWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (user != null) {
          debugPrint('✅ Registration successful: ${user.email}');
          setState(() {
            _successMessage =
                'Account created successfully! Welcome ${_nameController.text.trim()}!';
          });

          // Wait a moment to show success message
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          debugPrint('❌ Registration failed: User is null');
          setState(() {
            _errorMessage = 'Failed to create account. Please try again.';
          });
        }
      } else {
        debugPrint('🔄 Starting sign in process...');
        user = await _firebaseService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null) {
          debugPrint('✅ Sign in successful: ${user.email}');
          setState(() {
            _successMessage = 'Welcome back!';
          });

          // Wait a moment to show success message
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          debugPrint('❌ Sign in failed: User is null');
          setState(() {
            _errorMessage = 'Invalid email or password. Please try again.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e.code);
        });
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'An unexpected error occurred. Please check your internet connection and try again.';
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

  // ✅ IMPROVED: Better error messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in instead';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Contact support';
      default:
        return 'Authentication failed ($code). Please try again';
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _successMessage = null;
      // ✅ DON'T clear form fields to preserve user input
      // Only clear if user explicitly wants to switch
    });
  }

  // ✅ IMPROVED: Continue as guest with Firebase anonymous auth
  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      debugPrint('🔄 Signing in as guest...');
      final user = await _firebaseService.signInAsGuest();

      if (user != null) {
        debugPrint('✅ Guest sign in successful');
        setState(() {
          _successMessage = 'Welcome, Guest!';
        });

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        debugPrint('❌ Guest sign in failed');
        setState(() {
          _errorMessage = 'Failed to continue as guest. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('❌ Guest sign in error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error continuing as guest: ${e.toString()}';
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

  // ✅ NEW: Clear all form fields
  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
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
                  Text(
                    _isSignUp
                        ? 'Create an account to sync your favorites'
                        : 'Sign in to sync your favorites across devices',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Auth Form Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              // ✅ NEW: Clear form button
                              IconButton(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear form',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ✅ IMPROVED: Name field with validation
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ✅ IMPROVED: Email field with validation
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ✅ IMPROVED: Password field with validation
                          TextFormField(
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
                              helperText:
                                  _isSignUp ? 'Minimum 6 characters' : null,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (_isSignUp && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // ✅ SUCCESS MESSAGE
                          if (_successMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green)),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_successMessage!,
                                          style: const TextStyle(
                                              color: Colors.green))),
                                ],
                              ),
                            ),
                          ],

                          // ✅ ERROR MESSAGE
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

                          // Sign In/Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25))),
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Please wait...'),
                                      ],
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Sign In',
                                      style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle between sign in and sign up
                          TextButton(
                            onPressed: _isLoading ? null : _toggleAuthMode,
                            child: Text(_isSignUp
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Footer Section - Guest option
                  TextButton.icon(
                    onPressed: _isLoading ? null : _continueAsGuest,
                    icon:
                        const Icon(Icons.person_outline, color: Colors.white70),
                    label: const Text('Continue as Guest',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse songs without an account\n(favorites won\'t be saved)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                        widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white70),
                    tooltip: 'Toggle theme',
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
