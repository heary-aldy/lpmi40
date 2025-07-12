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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  bool _showVerificationMessage = false; // ✅ NEW: Track verification message

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ✅ UPDATED: Show verification message after successful registration
  Future<void> _signInWithEmail() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _showVerificationMessage = false;
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
        // Step 1: Create user account with email verification
        user = await _firebaseService.createUserWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (user != null) {
          // Step 2: Wait for user to be fully created and reload
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            await user.reload();
          } catch (reloadError) {
            // Continue anyway
          }

          // Step 3: User created successfully

          setState(() {
            _successMessage =
                'Account created successfully! Welcome ${_nameController.text.trim()}!';
            _showVerificationMessage = true; // ✅ NEW: Show verification message
          });

          // Step 4: Wait to show success message longer for verification notice
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to create account. Please try again.';
          });
        }
      } else {
        user = await _firebaseService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null) {
          setState(() {
            _successMessage = 'Welcome back!';
          });

          // Wait a moment to show success message
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid email or password. Please try again.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e.code);
        });

        // ✅ NEW: Show special dialog for duplicate email
        if (e.code == 'email-already-in-database' ||
            e.code == 'email-already-in-use') {
          // Optional: Show the helpful dialog
          _showDuplicateEmailDialog();
        }
      }
    } catch (e) {
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

  // ✅ COMPREHENSIVE: Better error messages with all Firebase error codes
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      // Authentication errors
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
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Contact support';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials';

      // Registration specific errors
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in instead';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers';

      // ✅ NEW: Handle the database email duplication error
      case 'email-already-in-database':
        return 'This email is already registered in our system. Please try signing in instead, or contact support if you believe this is an error.';

      // Network errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again';
      case 'timeout':
        return 'Request timed out. Please check your connection and try again';

      // ✅ NEW: Handle Firebase SDK type cast recovery errors
      case 'type-cast-recovery-failed':
        return 'Authentication succeeded but there was a technical issue. Please try signing in again.';
      case 'firebase-not-initialized':
        return 'Firebase is not properly configured. Please contact support.';

      default:
        return 'Authentication failed ($code). Please try again or contact support if the problem persists';
    }
  }

  // ✅ NEW: Show helpful dialog for duplicate email
  void _showDuplicateEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Already Registered'),
        content: const Text(
          'This email is already associated with an account. Would you like to:\n\n'
          '• Try signing in instead\n'
          '• Reset your password if you forgot it\n'
          '• Contact support if you believe this is an error',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Switch to sign in mode
              setState(() {
                _isSignUp = false;
                _errorMessage = null;
              });
            },
            child: const Text('Sign In'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // You can add password reset functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset feature coming soon!'),
                ),
              );
            },
            child: const Text('Reset Password'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _successMessage = null;
      _showVerificationMessage = false; // ✅ NEW: Reset verification message
      // Clear the name field when switching to sign in
      if (!_isSignUp) {
        _nameController.clear();
      }
    });
  }

  // ✅ NEW: Simple skip authentication - no Firebase interaction
  void _skipAuthentication() {
    Navigator.of(context).pop();
  }

  // ✅ NEW: Clear all form fields
  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _showVerificationMessage = false; // ✅ NEW: Reset verification message
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset('assets/images/header_image.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  )),
          Container(color: Colors.black.withValues(alpha: 0.6)),
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
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Auth Form Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
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
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: _clearForm,
                                icon: Icon(Icons.clear,
                                    color: theme.iconTheme.color),
                                tooltip: 'Clear form',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Name field for sign up
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  helperText: 'Enter your full name'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                if (value.trim().length > 50) {
                                  return 'Name must be less than 50 characters';
                                }
                                if (!RegExp(r"^[a-zA-Z\s\-'\.]+$")
                                    .hasMatch(value.trim())) {
                                  return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                helperText: 'Enter your email address'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: theme.textTheme.bodyLarge,
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
                              helperText: _isSignUp
                                  ? 'Minimum 6 characters, mix letters and numbers'
                                  : 'Enter your password',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (_isSignUp) {
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
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
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green)),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(_successMessage!,
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight:
                                                      FontWeight.w500))),
                                    ],
                                  ),
                                  // ✅ NEW: Email verification notice
                                  if (_showVerificationMessage) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.mail_outline,
                                            color: Colors.blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'A verification email has been sent to ${_emailController.text.trim()}. Please check your inbox.',
                                            style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(25)),
                                  elevation: 2),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(_isSignUp
                                            ? 'Creating Account...'
                                            : 'Signing In...'),
                                      ],
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Sign In',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle between sign in and sign up
                          TextButton(
                            onPressed: _isLoading ? null : _toggleAuthMode,
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Sign In'
                                  : 'Don\'t have an account? Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Skip authentication button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _skipAuthentication,
                      icon: const Icon(Icons.book_outlined, size: 20),
                      label: const Text('Continue to browse song lyric'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.9),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse songs without creating an account\n(favorites won\'t be saved)',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                        widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white.withValues(alpha: 0.8)),
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
