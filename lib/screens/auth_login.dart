import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

import '../screens/main_screen.dart';
import '../provider/supabase_provider.dart';
import '../widgets/show_hide_password_field.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
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
  TextEditingController controller = TextEditingController();
  //bool _password2Visible = true;
  //bool _newpasswordVisible = true;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;
  late final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _confirmController = TextEditingController();
  late final TextEditingController _newpasswordController = TextEditingController();
  late final TextEditingController _codeController = TextEditingController();
  final Map<String, String> stepSignIn = {'btn': 'Sign in', 'title': 'Sign in form'};
  final Map<String, String> stepSignUp = {'btn': 'Sign up', 'title': 'Sign up form'};
  final Map<String, String> stepForgot = {'btn': 'Recovery', 'title': 'Reset password form'};
  //final Map<String, String> stepVerify = {'btn': 'Verify email', 'title': 'Check your email.'};
  final Map<String, String> stepReset = {'btn': 'Reset password', 'title': 'Recover account form'};

  late Map<String, String> authStep; // register, recovery, confirm

  final TurnstileController _controller = TurnstileController();
  final TurnstileOptions _options = TurnstileOptions(
    size: TurnstileSize.normal,
    theme: TurnstileTheme.light,
    refreshExpired: TurnstileRefreshExpired.auto,
    language: 'en',
    retryAutomatically: false,
  );

  String? _captchaToken;
  Map<String, dynamic> error = {};
  late SupabaseClient supabase;

  /*void _showSnackBar(BuildContext argContext, String argMessage, String? backgroundColor) {
    Color bgColor = Theme.of(context).colorScheme.primary;
    Color? textColor;
    if (backgroundColor == 'warning') {
      bgColor = Colors.yellow.shade700;
      textColor = Colors.black87;
    } else if (backgroundColor == 'error') {
      bgColor = Colors.red.shade500;
    } else if (backgroundColor == 'success') {
      bgColor = Colors.green;
    } else {
      bgColor = Theme.of(argContext).colorScheme.primary;
    }
    ScaffoldMessenger.of(argContext).showSnackBar(
      SnackBar(content: Text(argMessage, style: TextStyle(color: textColor ?? Colors.white)), backgroundColor: bgColor),
    );
  }*/

  void _showSnackBar(
    BuildContext argContext,
    String argMessage,
    String? backgroundColor, {
    Duration? duration, // Hacer duración opcional
    SnackBarAction? action,
    VoidCallback? onHideCallback, // Parámetro para el callback
  }) {
    Color bgColor = Theme.of(argContext).colorScheme.primary;
    Color? textColor;

    // Determina el color de fondo y el color del texto según el tipo
    if (backgroundColor == 'warning') {
      bgColor = Colors.yellow.shade700;
      textColor = Colors.black87;
    } else if (backgroundColor == 'error') {
      bgColor = Colors.red.shade500;
      textColor = Colors.white;
    } else if (backgroundColor == 'success') {
      bgColor = Colors.green;
      textColor = Colors.white;
    } else {
      bgColor = Colors.blueAccent;
      textColor = Colors.black87;
    }

    // Si no se proporciona duración, usa el valor por defecto
    Duration snackBarDuration = duration ?? const Duration(seconds: 3);

    // Crea el SnackBar
    final snackBar = SnackBar(
      content: Text(
        argMessage,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: bgColor,
      duration: snackBarDuration,
      action: action,
    );

    // Muestra el SnackBar
    ScaffoldMessenger.of(argContext).showSnackBar(snackBar);

    Future.delayed(snackBarDuration, () {
      if (onHideCallback != null) {
        onHideCallback();
      }
    });
  }

  /*class _toggleIcon extends Widget() {
    return _showPassword ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off_outlined);
  }*/

  Future<bool> userDeleting(String email) async {
    try {
      final bool pending = await supabase.rpc('check_user_pending_deletion', params: {'email': email});
      return pending;
      // ignore: empty_catches
    } catch (e) {}
    return false;
  }

  Future<void> _signIn() async {
    var validateError = await validateLoginForm(email: true, password: true);
    if (validateError.isNotEmpty) {
      setState(() {});
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(), password: _passwordController.text, captchaToken: _captchaToken);

      if (mounted) {
        _emailController.clear();
        _passwordController.clear();
      }
    } on AuthException catch (error) {
      String errorMessage = '';

      if (error.message.contains('invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (error.message.contains('email not confirmed')) {
        errorMessage = 'Please confirm your email before logging in.';
      } else {
        errorMessage = '';
      }
      if (mounted) {
        if (errorMessage.isNotEmpty) {
          _showSnackBar(context, errorMessage, 'error');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _captchaToken = null;
        });
      }
      await _controller.refreshToken();
    }
  }

  Future<Map<String, dynamic>> validateLoginForm(
      {bool email = false,
      bool password = false,
      bool confirm = false,
      bool newpass = false,
      bool code = false,
      bool captcha = true}) async {
    if (email == true) {
      final pending = await userDeleting(_emailController.text.trim());
      if (_emailController.text.isEmpty) {
        error['email_empty'] = 'Email is required!';
      }
      if (pending == true) {
        error['email_wrong'] = 'The email is pending deletion!';
      } else {
        if (_isValidEmail(_emailController.text) == false) {
          error['email_wrong'] = 'The email is invalid!';
        }
      }
    }

    if (newpass == true) {
      if (_newpasswordController.text.isEmpty) {
        error['newpass_empty'] = 'Enter a new password!';
      } else {
        if (_newpasswordController.text.length < 6) {
          error['newpass_wrong'] = 'The new password is too short. (${_newpasswordController.text.length}/6+)';
        }
      }
    }

    if (password == true) {
      if (_passwordController.text.isEmpty) {
        error['password_empty'] = 'Enter a password!';
      } else {
        if (_passwordController.text.length < 6) {
          error['password_wrong'] = 'Password is too short. (${_passwordController.text.length}/6+)';
        }
      }
    }

    if (confirm == true) {
      if (_confirmController.text.isEmpty) {
        error['confirm_empty'] = 'Confirm the password.';
      } else {
        if (_confirmController.text.length < 6) {
          error['confirm_wrong'] = 'Password confirmation is too short. (${_confirmController.text.length}/6+)';
        }
      }
    }

    if (code == true) {
      if (_codeController.text.isEmpty) {
        error['code_empty'] = 'Enter the code send to the email.';
      } else {
        if (_codeController.text.length < 6) {
          error['code_wrong'] = 'The code must be 6 digits long. (${_codeController.text.length}/6)';
        }
      }
    }

    if (password == true &&
        confirm == true &&
        _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty) {
      if (_passwordController.text != _confirmController.text) {
        error['match'] = 'The passwords do not match.';
      }
    }
    if (captcha == true && (_captchaToken == null || _captchaToken!.isEmpty)) {
      error['captcha'] = 'Check the captcha!';
    }
    return error;
  }

  bool _isValidEmail(String email) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  Future<void> _signUpWithEmail() async {
    var validateError = await validateLoginForm(email: true, password: true, confirm: true);
    if (validateError.isNotEmpty) {
      setState(() {});
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      final res = await supabase.auth
          .signUp(email: _emailController.text.trim(), password: _passwordController.text, captchaToken: _captchaToken);

      if (mounted) {
        if (res.user!.identities!.isEmpty) {
          _showSnackBar(context, 'Your email is already registered.', 'warning');
        } else {
          _showSnackBar(context, 'Check your email for a login link!', 'success');
        }
        setState(() {
          authStep = stepSignIn;
        });
        //_emailController.clear();
        //_passwordController.clear();
        _confirmController.clear();
      }
    } on AuthException catch (error) {
      String errorMessage;

      if (error.message.contains('invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (error.message.contains('email not confirmed')) {
        errorMessage = 'Please confirm your email before logging in.';
      } else {
        errorMessage = 'error'; //error.message
      }
      if (mounted) {
        if (errorMessage != 'error') {
          _showSnackBar(context, errorMessage, 'error');
        }
      }
    } catch (error) {
      if (mounted) {
        //_showSnackBar(context, 'Unexpected error occurred', 'error');
        _showSnackBar(context, error.toString(), 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _captchaToken = null;
        });
      }
      await _controller.refreshToken();
    }
  }

  Future<void> _signInRecoveryByEmail() async {
    var validateError = await validateLoginForm(email: true);
    if (validateError.isNotEmpty) {
      setState(() {});
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      //debugPrint(_emailController.text);
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim(), captchaToken: _captchaToken);

      if (mounted) {
        _showSnackBar(context, 'Check your email for reset code!', 'success');
        _newpasswordController.clear();
        _codeController.clear();
        setState(() {
          authStep = stepReset;
        });

        //_emailController.t
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showSnackBar(context, error.message, 'error');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _captchaToken = null;
        });
      }
      await _controller.refreshToken();
    }
  }

  Future<void> _resetPassword() async {
    var validateError = await validateLoginForm(email: true, code: true, newpass: true);
    if (validateError.isNotEmpty) {
      setState(() {});
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.verifyOTP(
          email: _emailController.text,
          token: _codeController.text,
          type: OtpType.recovery,
          captchaToken: _captchaToken);
      await supabase.auth.updateUser(
        UserAttributes(password: _newpasswordController.text.trim()),
      );

      if (mounted) {
        _showSnackBar(context, 'Reset password successful!', 'success', onHideCallback: () {
          //debugPrint('..................entrando......................');
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BLEMainScreen())).then((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        });
        //setState(() {});
      }
      //await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
    } on AuthException catch (error) {
      if (mounted) {
        if (error.message.startsWith('New password should be different')) {
          _showSnackBar(context, 'Your lost password is: "${_newpasswordController.text}"', 'warning',
              onHideCallback: () {
            //debugPrint('..................entrando......................');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BLEMainScreen())).then((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          });
          // setState(() {
          //   _captchaToken = null;
          // });
        }
      } else {
        if (mounted) {
          _showSnackBar(context, error.message, 'error');
          // setState(() {
          //   _captchaToken = null;
          // });
        }
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Unexpected error occurred', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _captchaToken = null;
        });
      }
      await _controller.refreshToken();
    }
  }

  @override
  void initState() {
    setState(() {
      super.initState();
      //_showPassword = true;
      //_password2Visible = true;
      //_newpasswordVisible = true;
      supabase = SupabaseProvider.getClient(context);
      authStep = stepSignIn;
      _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;

        if (event == AuthChangeEvent.signedIn) {
          if (mounted) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BLEMainScreen())).then((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          }
        }
        /*if (event == AuthChangeEvent.userUpdated) {
          if (mounted) {
            //Future.delayed(const Duration(seconds: 2)).then((val) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BLEMainScreen())).then((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
            //});
          }
        }*/
        /*if (event == AuthChangeEvent.passwordRecovery) {
          if (mounted) {
            //Future.delayed(const Duration(seconds: 2)).then((val) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BLEMainScreen())).then((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
            //});
          }
        }*/
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _codeController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 243, 250),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 214, 236, 235),
        title: const Center(
          child: Text(
            'eAquaSaver',
            style: TextStyle(letterSpacing: 4),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, state) {
          return _buildLoginForm(context, state);
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, ConnectivityState state) {
    return ListView(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
      children: [
        const Positioned(
          top: 0,
          child: Image(
            image: AssetImage('assets/company_logo.png'),
            width: 100,
            height: 150,
          ),
        ),
        if (state is ConnectivityOnline) ...[
          Center(
            child: Text(
              authStep['title']!,
              style: TextStyle(fontSize: 22, color: Colors.cyan.shade800),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (state is ConnectivityOffline) ...[
          const SizedBox(height: 150),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Center(
                child: Text(
              'No internet connection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red.shade500),
            )),
            Center(
                child: TextButton.icon(
                    icon: const Icon(Icons.cloud_off_outlined), label: const Text('Offline'), onPressed: null))
          ])
        ],
        if (state is ConnectivityOnline) ...[
          TextFormField(
            enabled: authStep != stepReset,
            controller: _emailController,
            decoration: const InputDecoration(
              icon: Icon(Icons.email_outlined),
              //hintText: 'The email address?',
              labelText: 'email',
            ),
            onChanged: (value) => {
              if (value.isNotEmpty) {error.remove('email_empty'), setState(() {})},
              if (_isValidEmail(value)) {error.remove('email_wrong'), setState(() {})},
            },
          ),
          Offstage(
            offstage: authStep != stepReset,
            child: TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                  icon: Icon(Icons.security_update_good),
                  //hintText: 'The email address?',
                  labelText: 'code',
                  counterText: ""),
              maxLength: 6,
              keyboardType: TextInputType.number,
              onChanged: (code) {
                if (code.isNotEmpty) {
                  error.remove('code_empty');
                  setState(() {});
                }
                if (code.length == 6) {
                  error.remove('code_wrong');
                  setState(() {});
                }
              },
            ),
          ),
          Offstage(
            offstage: authStep != stepSignUp && authStep != stepSignIn,
            child: ShowHidePasswordField(
              controller: _passwordController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                labelText: 'password',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  error.remove('password_empty');
                  setState(() {});
                }
                if (value.length == 6) {
                  error.remove('password_wrong');
                  setState(() {});
                }
                if (_passwordController.text == _confirmController.text) {
                  error.remove('match');
                  setState(() {});
                }
              },
            ),
          ),
          Offstage(
            offstage: authStep != stepReset,
            child: ShowHidePasswordField(
              controller: _newpasswordController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                labelText: 'new password',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  error.remove('newpass_empty');
                  setState(() {});
                }
                if (value.length >= 6) {
                  error.remove('newpass_wrong');
                  setState(() {});
                }
              },
            ),
          ),
          Offstage(
            offstage: authStep != stepSignUp,
            child: ShowHidePasswordField(
              controller: _confirmController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: const InputDecoration(
                icon: Icon(Icons.lock_outline),
                labelText: 'repeat',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  error.remove('confirm_empty');
                  setState(() {});
                }
                if (value.length == 6) {
                  error.remove('confirm_wrong');
                  setState(() {});
                }
                if (_passwordController.text == _confirmController.text) {
                  error.remove('match');
                  setState(() {});
                }
              },
            ),
          ),
          const SizedBox(height: 20.0),
          Center(
            child: CloudFlareTurnstile(
              siteKey: '0x4AAAAAAAc8EpaDnPZMolAQ',
              options: _options,
              controller: _controller,
              onTokenRecived: (token) {
                error.remove('captcha');
                setState(() {
                  _captchaToken = token;
                });
              },
              onTokenExpired: () async {
                await _controller.refreshToken();
              },
              onError: (error) async {
                await _controller.refreshToken();
              },
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                color: Colors.cyanAccent,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ...error.values.map((e) =>
                        Text(e, textAlign: TextAlign.left, style: TextStyle(color: Colors.red.shade500, fontSize: 12))),
                  ],
                ),
              ),
              Container(
                width: 40,
                color: Colors.cyanAccent,
              ),
            ],
          ),
          /*TextButton(
              onPressed: () async {
                await _controller.refreshToken();
              },
              child: const Text('Reload captcha', style: TextStyle(color: Color(0xFFEE8418)))),*/
          const SizedBox(height: 18),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 70.0,
            ),
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade500, fixedSize: const Size(150, 10)),
              child: Text(_isLoading ? 'Loading' : authStep['btn']!),
            ),
          ),
          Offstage(
            offstage: authStep == stepSignIn,
            child: TextButton(
              onPressed: () => {
                error.clear(),
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
                error.clear(),
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
                error.clear(),
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
        ]
      ],
    );
  }
}
