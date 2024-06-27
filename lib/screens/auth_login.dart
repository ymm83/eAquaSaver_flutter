import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:show_hide_password/show_hide_password.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

import '../main.dart';
//hcaptcha
//sitekey 001ee992-3a50-4a5a-bf5e-9b66a4a414e4
//secret ES_c6f0da2654da477ba197f8f9fea93592
//cloudflare
//sitekey 0x4AAAAAAAc73oNIZFZ3mrD9
//secret 0x4AAAAAAAc73mmZlrIslaef9sNXfrm6mis

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final bool _redirecting = false;
  TextEditingController controller = TextEditingController();
  //bool _password2Visible = true;
  //bool _newpasswordVisible = true;
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

  final TurnstileController _controller = TurnstileController();
  final TurnstileOptions _options = TurnstileOptions(
    size: TurnstileSize.normal,
    theme: TurnstileTheme.light,
    refreshExpired: TurnstileRefreshExpired.manual,
    language: 'en',
    retryAutomatically: false,
  );

  String? _token;

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

  /*class _toggleIcon extends Widget() {
    return _showPassword ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off_outlined);
  }*/

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(context, 'Email and password cannot be empty', 'primary');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(), password: _passwordController.text, captchaToken: _token);

      if (mounted) {
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

  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await supabase.rpc('is_email_exist', params: {'email': email});
      //return response['rpc_is_email_exist'];
      print(response);
      print(4444444444444444);
      return response;
      // Si la consulta devuelve un resultado, el email ya está registrado
    } catch (error) {
      return false;
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(context, 'Email and password cannot be empty', 'error');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      final resp = await supabase.auth
          .signUp(email: _emailController.text.trim(), password: _passwordController.text, captchaToken: _token);
      print('RESPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP');
      print(resp.user);

      if (mounted) {
        _showSnackBar(context, 'Check your email for a login link!', 'success');
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
        //_showSnackBar(context, 'Unexpected error occurred', 'error');
        _showSnackBar(context, error.toString(), 'error');
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
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim(), captchaToken: _token);

      if (mounted) {
        _showSnackBar(context, 'Check your email for reset code!', 'success');
        _newpasswordController.clear();
        _tokenController.clear();
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
      return;
    }
    if (_tokenController.text.length < 6) {
      _showSnackBar(context, 'The token must be 6 digits long.', 'error');
      return;
    }
    if (_newpasswordController.text.trim().length < 6) {
      _showSnackBar(context, 'The password must be at least 6 characters', 'error');
      return;
    }
    if (_newpasswordController.text.trim().isEmpty) {
      _showSnackBar(context, 'The new password cannot be empty', 'error');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      final recovery = await supabase.auth.verifyOTP(
          email: _emailController.text, token: _tokenController.text, type: OtpType.recovery, captchaToken: _token);
      print(recovery);
      await supabase.auth.updateUser(
        UserAttributes(password: _newpasswordController.text.trim()),
      );
      _showSnackBar(context, 'Reset password successful!', 'success');
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
      super.initState();
      //_showPassword = true;
      //_password2Visible = true;
      //_newpasswordVisible = true;

      authStep = stepSignIn;
      _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;

        print('Eventtttttttttttttt is: $event');
        // final session = data.session;
        if (event == AuthChangeEvent.signedOut) {
          //Navigator.of(context).pushReplacementNamed('/login');
        }
        if (event == AuthChangeEvent.signedIn) {
          //if (session != null) {
          Navigator.of(context).pushReplacementNamed('/main');
          //}
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _tokenController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: ,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Positioned(
            top: -150,
            child: Image(
              image: AssetImage('assets/company_logo.png'),
              width: 100,
              height: 150,
            ),
          ),
          const Text('Sign in with your email and password below'),
          const SizedBox(height: 18),
          TextFormField(
            enabled: authStep != stepReset,
            controller: _emailController,
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
            child: ShowHidePasswordTextField(
              controller: _passwordController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                labelText: 'password',
              ),
            ),
          ),
          Offstage(
            offstage: authStep != stepReset,
            child: ShowHidePasswordTextField(
              controller: _newpasswordController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                labelText: 'new password',
              ),
            ),
          ),
          Offstage(
            offstage: authStep != stepSignUp,
            child: ShowHidePasswordTextField(
              controller: _password2Controller,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                labelText: 'repeat',
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          CloudFlareTurnstile(
            siteKey: '0x4AAAAAAAc8EpaDnPZMolAQ',
            options: _options,
            controller: _controller,
            onTokenRecived: (token) {
              setState(() {
                _token = token;
              });
            },
            onTokenExpired: () async {
              await _controller.refreshToken();
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            },
          ),
          TextButton(
              onPressed: () async {
                await _controller.refreshToken();
              },
              child: const Text('Reload captcha', style: TextStyle(color: Color(0xFFEE8418)))),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(_isLoading ? 'Loading' : authStep),
          ),
          Offstage(
            offstage: authStep == stepSignIn,
            child: TextButton(
              onPressed: () => {
                setState(() {
                  authStep = stepSignIn;
                }),
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
                //final response = await supabase.rpc('is_email_exist', params: {'email': _emailController.text});
                //print(response['is_email_exist']);
                setState(() {
                  authStep = stepForgot;
                })
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
