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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ✅ IMPROVED: Better validation and comprehensive error handling
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
        // Step 1: Create user account
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

          // Step 3: Get updated user reference
          final updatedUser = FirebaseAuth.instance.currentUser;

          setState(() {
            _successMessage =
                'Account created successfully! Welcome ${_nameController.text.trim()}!';
          });

          // Step 4: Wait to show success message
          await Future.delayed(const Duration(seconds: 1));

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

      // Network errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again';
      case 'timeout':
        return 'Request timed out. Please check your connection and try again';

      // Other common errors
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please restart the process';
      case 'missing-verification-code':
        return 'Please enter the verification code';
      case 'missing-verification-id':
        return 'Verification ID is missing. Please restart the process';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'invalid-action-code':
        return 'The action code is invalid. This may happen if the code is malformed or has expired';
      case 'expired-action-code':
        return 'The action code has expired. Please request a new one';
      case 'invalid-message-payload':
        return 'The email template is invalid';
      case 'invalid-sender':
        return 'The email sender is invalid';
      case 'invalid-recipient-email':
        return 'The recipient email is invalid';
      case 'missing-android-pkg-name':
        return 'Android package name is missing';
      case 'missing-continue-uri':
        return 'Continue URL is missing';
      case 'missing-ios-bundle-id':
        return 'iOS bundle ID is missing';
      case 'invalid-continue-uri':
        return 'Continue URL is invalid';
      case 'unauthorized-continue-uri':
        return 'Continue URL is not authorized';
      case 'invalid-dynamic-link-domain':
        return 'Dynamic link domain is invalid';
      case 'argument-error':
        return 'Invalid argument provided';
      case 'invalid-persistence-type':
        return 'Invalid persistence type';
      case 'unsupported-persistence-type':
        return 'Persistence type is not supported';
      case 'invalid-custom-token':
        return 'Custom token is invalid';
      case 'custom-token-mismatch':
        return 'Custom token does not match';
      case 'invalid-identifier':
        return 'Invalid identifier provided';
      case 'invalid-creation-time':
        return 'Invalid creation time';
      case 'invalid-last-sign-in-time':
        return 'Invalid last sign-in time';
      case 'invalid-provider-data':
        return 'Invalid provider data';
      case 'invalid-oauth-responsetype':
        return 'Invalid OAuth response type';
      case 'invalid-oauth-clientid':
        return 'Invalid OAuth client ID';
      case 'invalid-oauth-client-secret':
        return 'Invalid OAuth client secret';
      case 'invalid-cert-hash':
        return 'Invalid certificate hash';
      case 'invalid-api-key':
        return 'Invalid API key';
      case 'invalid-user-import':
        return 'Invalid user import';
      case 'invalid-provider-id':
        return 'Invalid provider ID';
      case 'invalid-supported-first-factors':
        return 'Invalid supported first factors';

      // Permission errors
      case 'claims-too-large':
        return 'Claims payload is too large';
      case 'id-token-expired':
        return 'ID token has expired';
      case 'id-token-revoked':
        return 'ID token has been revoked';
      case 'insufficient-permission':
        return 'Insufficient permission to perform this operation';
      case 'internal-error':
        return 'Internal error occurred. Please try again';
      case 'invalid-argument':
        return 'Invalid argument provided';
      case 'invalid-claims':
        return 'Invalid claims provided';
      case 'invalid-creation-time':
        return 'Invalid creation time provided';
      case 'invalid-disabled-field':
        return 'Invalid disabled field';
      case 'invalid-display-name':
        return 'Invalid display name';
      case 'invalid-email-verified':
        return 'Invalid email verified status';
      case 'invalid-hash-algorithm':
        return 'Invalid hash algorithm';
      case 'invalid-hash-block-size':
        return 'Invalid hash block size';
      case 'invalid-hash-derived-key-length':
        return 'Invalid hash derived key length';
      case 'invalid-hash-key':
        return 'Invalid hash key';
      case 'invalid-hash-memory-cost':
        return 'Invalid hash memory cost';
      case 'invalid-hash-parallelization':
        return 'Invalid hash parallelization';
      case 'invalid-hash-rounds':
        return 'Invalid hash rounds';
      case 'invalid-hash-salt-separator':
        return 'Invalid hash salt separator';
      case 'invalid-id-token':
        return 'Invalid ID token';
      case 'invalid-last-sign-in-time':
        return 'Invalid last sign-in time';
      case 'invalid-page-token':
        return 'Invalid page token';
      case 'invalid-password':
        return 'Invalid password';
      case 'invalid-password-hash':
        return 'Invalid password hash';
      case 'invalid-password-salt':
        return 'Invalid password salt';
      case 'invalid-phone-number':
        return 'Invalid phone number';
      case 'invalid-photo-url':
        return 'Invalid photo URL';
      case 'invalid-project-id':
        return 'Invalid project ID';
      case 'invalid-provider-uid':
        return 'Invalid provider UID';
      case 'invalid-session-cookie-duration':
        return 'Invalid session cookie duration';
      case 'invalid-uid':
        return 'Invalid user ID';
      case 'invalid-user-import':
        return 'Invalid user import';
      case 'maximum-user-count-exceeded':
        return 'Maximum user count exceeded';
      case 'missing-hash-algorithm':
        return 'Missing hash algorithm';
      case 'missing-uid':
        return 'Missing user ID';
      case 'reserved-claims':
        return 'Reserved claims used';
      case 'session-cookie-expired':
        return 'Session cookie has expired';
      case 'session-cookie-revoked':
        return 'Session cookie has been revoked';
      case 'uid-already-exists':
        return 'User ID already exists';
      case 'unauthorized-domain':
        return 'Domain is not authorized';
      case 'user-not-found':
        return 'User not found';

      // ✅ NEW: Handle Firebase SDK type cast recovery errors
      case 'type-cast-recovery-failed':
        return 'Authentication succeeded but there was a technical issue. Please try signing in again.';
      case 'firebase-not-initialized':
        return 'Firebase is not properly configured. Please contact support.';

      default:
        return 'Authentication failed ($code). Please try again or contact support if the problem persists';
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _successMessage = null;
      // Clear the name field when switching to sign in
      if (!_isSignUp) {
        _nameController.clear();
      }
    });
  }

  // ✅ IMPROVED: Continue as guest with proper error handling
  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = await _firebaseService.signInAsGuest();

      if (user != null) {
        setState(() {
          _successMessage = 'Welcome, Guest!';
        });

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to continue as guest. Please try again.';
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
          _errorMessage = 'Error continuing as guest. Please try again.';
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
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear form',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ✅ IMPROVED: Name field with comprehensive validation
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
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
                                // Check for valid characters (letters, spaces, hyphens, apostrophes)
                                if (!RegExp(r"^[a-zA-Z\s\-'\.]+$")
                                    .hasMatch(value.trim())) {
                                  return 'Name can only contain letters, spaces, hyphens, and apostrophes';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ✅ IMPROVED: Email field with comprehensive validation
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
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
                              // More comprehensive email validation
                              if (!RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ✅ IMPROVED: Password field with better validation
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
                                // For new accounts, encourage stronger passwords
                                if (value.length < 8) {
                                  // Don't block but warn about weak password
                                  return null; // Firebase will handle weak password error
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
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500))),
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
