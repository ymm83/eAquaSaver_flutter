import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;
  late final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _password2Controller = TextEditingController();
  late final TextEditingController _newpasswordController = TextEditingController();
  late final TextEditingController _tokenController = TextEditingController();
  final String stepSignIn = 'Sign in';
  final String stepSignUp = 'Sign up';
  final String stepForgot = 'Recovery';
  final String stepVerify = 'Verify email';
  final String stepReset = 'Reset password';

  late String authStep; // register, recovery, confirm

  void _showSnackBar(BuildContext argContext, String argMessage, String? backgroundColor) {
    Color bgColor = Theme.of(context).colorScheme.primary;
    if (backgroundColor == 'secondary') {
      bgColor = Theme.of(argContext).colorScheme.secondary;
    } else if (backgroundColor == 'error') {
      bgColor = Theme.of(argContext).colorScheme.error;
    } else if (backgroundColor == 'success') {
      bgColor = Colors.green;
    } else {
      bgColor = Theme.of(argContext).colorScheme.primary;
    }
    ScaffoldMessenger.of(argContext).showSnackBar(
      SnackBar(content: Text(argMessage), backgroundColor: bgColor),
    );
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(context, 'Email and password cannot be empty', 'primary');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.signInWithPassword(email: _emailController.text.trim(), password: _passwordController.text);

      if (mounted) {
        _showSnackBar(context, 'Check your email for a login link!', 'primary');
        _emailController.clear();
        _passwordController.clear();
      }
    } on AuthException catch (error) {
      String errorMessage;

      if (error.message.contains('invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (error.message.contains('email not confirmed')) {
        errorMessage = 'Please confirm your email before logging in.';
      } else {
        errorMessage = error.message;
      }
      _showSnackBar(context, errorMessage, 'error');
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(context, 'Email and password cannot be empty');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.signUp(email: _emailController.text.trim(), password: _passwordController.text);

      /*if (response.error != null) {
        // Handle login error
        throw AuthException('Login error: ${response.error!.message}');
      }*/
      if (mounted) {
        _showSnackBar(context, 'Check your email for a login link!');
        _emailController.clear();
        _passwordController.clear();
      }
    } on AuthException catch (error) {
      String errorMessage;

      if (error.message.contains('invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (error.message.contains('email not confirmed')) {
        errorMessage = 'Please confirm your email before logging in.';
      } else {
        errorMessage = error.message;
      }

      _showSnackBar(context, errorMessage, 'error');
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInRecoveryByEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar(context, 'Email cannot be empty', 'error');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      print(_emailController.text);
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());

      if (mounted) {
        _showSnackBar(context, 'Check your email for reset code!', 'success');
        _newpasswordController.clear();
        setState(() {
          authStep = stepReset;
        });
        //_emailController.t
      }
    } on AuthException catch (error) {
      _showSnackBar(context, error.message, 'error');
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_tokenController.text.trim().isEmpty) {
      _showSnackBar(context, 'The token cannot be empty', 'error');
    }
    if (_newpasswordController.text.trim().isEmpty) {
      _showSnackBar(context, 'The token cannot be empty', 'error');

      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      final recovery = await supabase.auth.verifyOTP(
        email: _emailController.text,
        token: _tokenController.text,
        type: OtpType.recovery,
      );
      print(recovery);
      await supabase.auth.updateUser(
        UserAttributes(password: _newpasswordController.text.trim()),
      );
      //await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
    } on AuthException catch (error) {
      _showSnackBar(context, error.message, 'error');
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
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
  void initState() {
    setState(() {
      authStep = stepReset;
      _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          Navigator.of(context).pushReplacementNamed('/main');
        }
      });
      super.initState();
    });
  }

  @override
  void dispose() {
    //_emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _tokenController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(authStep),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Sign in with your email and password below'),
          const SizedBox(height: 18),
          TextFormField(
            enabled: authStep != stepReset,
            controller: _emailController,
            //decoration: const InputDecoration(labelText: 'Email'),
            decoration: const InputDecoration(
              icon: Icon(Icons.email_outlined),
              //hintText: 'The email address?',
              labelText: 'email',
            ),
          ),
          Offstage(
            offstage: authStep != stepReset,
            child: TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                icon: Icon(Icons.security_update_good),
                //hintText: 'The email address?',
                labelText: 'token',
              ),
              validator: (value) {
                if (value!.isEmpty || value.length < 6) {
                  return 'Token does not match!';
                }
                return null;
              },
              maxLength: 6,
              keyboardType: TextInputType.number,
            ),
          ),
          Offstage(
            offstage: authStep != stepSignUp && authStep != stepSignIn,
            child: TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                //hintText: 'The email address?',
                labelText: 'password',
              ),
              obscureText: true,
            ),
          ),
          Offstage(
            offstage: authStep != stepReset,
            child: TextFormField(
              controller: _newpasswordController,
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                //hintText: 'The email address?',
                labelText: 'new password',
              ),
              obscureText: true,
            ),
          ),
          Offstage(
            offstage: authStep != stepSignUp,
            child: TextFormField(
              controller: _password2Controller,
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                //hintText: 'The email address?',
                labelText: 'repeat',
              ),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : authStep == stepSignIn
                    ? _signIn
                    : authStep == stepSignUp
                        ? _signUpWithEmail
                        : authStep == stepForgot
                            ? _signInRecoveryByEmail
                            : authStep == stepReset
                                ? _resetPassword
                                : null,
            child: Text(_isLoading ? 'Loading' : authStep),
          ),
          Offstage(
            offstage: authStep == stepSignIn,
            child: TextButton(
              onPressed: () => {
                setState(() {
                  authStep = stepSignIn;
                }),
                print(authStep)
              },
              child: const Text('Sign in',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          Offstage(
            offstage: authStep == stepSignUp,
            child: TextButton(
              onPressed: () => {
                setState(() {
                  authStep = stepSignUp;
                }),
                print(authStep)
              },
              child: const Text('Don\'t have an account? Sign up',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          Offstage(
            offstage: authStep == stepForgot,
            child: TextButton(
              onPressed: () => {
                setState(() {
                  authStep = stepForgot;
                }),
                print(authStep),
              },
              child: const Text('Forgot you password?',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
