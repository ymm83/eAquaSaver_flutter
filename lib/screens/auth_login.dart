import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

import '../provider/theme_provider.dart';
import '../screens/main_screen.dart';
import '../provider/supabase_provider.dart';
import '../utils/language.dart';
import '../utils/snackbar_helper.dart';
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

class AuthSteps {
  static const signIn = 'signin';
  static const signUp = 'signup';
  static const forgot = 'forgot';
  static const reset = 'reset';

  static Map<String, String> getTexts(String step) {
    final basePath = 'login.step.$step';
    return {
      'btn': '$basePath.btn'.tr(),
      'title': '$basePath.title'.tr(),
    };
  }
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

  String authStep = AuthSteps.signIn; // register, recovery, confirm

  final TurnstileController _controller = TurnstileController();
  late final TurnstileOptions _options;

  Language? selectedLang;
//selectedLang = languageList.singleWhere((e) => e.locale == context.locale);

  String? _captchaToken;
  Map<String, dynamic> error = {};
  late SupabaseClient supabase;

  /*class _toggleIcon extends Widget() {
    return _showPassword ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off_outlined);
  }*/

  final List<Language> languageList = [
    Language(locale: const Locale('en'), langName: 'lang.en'.tr()),
    Language(locale: const Locale('fr'), langName: 'lang.fr'.tr()),
    Language(locale: const Locale('es'), langName: 'lang.es'.tr()),
  ];

  TurnstileOptions _getTurnstileOptions(bool isDarkMode) {
    return TurnstileOptions(
      size: TurnstileSize.normal,
      theme: isDarkMode ? TurnstileTheme.dark : TurnstileTheme.light,
      refreshExpired: TurnstileRefreshExpired.auto,
      refreshTimeout: TurnstileRefreshTimeout.manual,
      language: _getTurnstileLanguageCode(context),
      retryAutomatically: false,
    );
  }

  Future<bool> userDeleting(String email) async {
    try {
      final bool pending = await supabase.rpc('check_user_pending_deletion', params: {'email': email});
      //debugPrint('pending_to delete: $pending');
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
        email: _emailController.text.trim(),
        password: _passwordController.text,
        captchaToken: _captchaToken,
      );

      if (mounted) {
        _emailController.clear();
        _passwordController.clear();
      }
    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _handleUnexpectedError();
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

  void _handleAuthException(AuthException e) {
    String errorMessage;
    if (e.message.contains('invalid login credentials')) {
      errorMessage = 'Correo o contraseña inválidos. Por favor, inténtalo de nuevo.';
    } else if (e.message.contains('email not confirmed')) {
      errorMessage = 'Por favor, confirma tu correo antes de iniciar sesión.';
    } else {
      errorMessage = 'Error de autenticación inesperado.';
    }

    if (mounted) {
      error['login'] = e.message;
      //showSnackBar(errorMessage, theme: 'error', icon: Icons.person_off);
    }
  }

  void _handleUnexpectedError() {
    if (mounted) {
      showSnackBar('Ocurrió un error inesperado', theme: 'error');
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
        error['email_empty'] = 'validation.email.required'.tr();
      }
      if (pending == true) {
        error['email_wrong'] = 'validation.email.pending_deletion'.tr();
      } else if (!_isValidEmail(_emailController.text)) {
        error['email_wrong'] = 'validation.email.invalid'.tr();
      }
    }

    if (newpass == true) {
      if (_newpasswordController.text.isEmpty) {
        error['newpass_empty'] = 'validation.new_password.required'.tr();
      } else if (_newpasswordController.text.length < 6) {
        error['newpass_wrong'] = 'validation.new_password.too_short'
            .tr(namedArgs: {'length': _newpasswordController.text.length.toString()});
      }
    }

    // ... (aplica el mismo patrón para los demás campos)

    if (password == true && confirm == true && _passwordController.text != _confirmController.text) {
      error['match'] = 'validation.confirm_password.mismatch'.tr();
    }

    if (captcha == true && (_captchaToken == null || _captchaToken!.isEmpty)) {
      error['captcha'] = 'validation.captcha.required'.tr();
    }

    return error;
  }

  /*Future<Map<String, dynamic>> validateLoginForm(
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
  }*/

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
          showSnackBar('Your email is already registered.', theme: 'warning');
        } else {
          showSnackBar('Check your email for a login link!', theme: 'success');
        }
        setState(() {
          authStep = AuthSteps.signIn;
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
          showSnackBar(errorMessage, theme: 'error');
        }
      }
    } catch (error) {
      if (mounted) {
        //_showSnackBar(context, 'Unexpected error occurred', 'error');
        showSnackBar(error.toString(), theme: 'error');
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
        showSnackBar('Check your email for reset code!', theme: 'success');
        _newpasswordController.clear();
        _codeController.clear();
        setState(() {
          authStep = AuthSteps.reset;
        });

        //_emailController.t
      }
    } on AuthException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('Unexpected error occurred', theme: 'error');
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
        showSnackBar('Reset password successful!', theme: 'success', onHideCallback: () {
          //debugPrint('..................entrando......................');
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => Theme(
                data: Theme.of(context), // Hereda el tema actual
                child: const BLEMainScreen(),
              ),
            ),
          )
              .then((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        });
        //setState(() {});
      }
      //await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
    } on AuthException catch (error) {
      if (mounted) {
        if (error.message.startsWith('New password should be different')) {
          showSnackBar('Your lost password is: "${_newpasswordController.text}"', theme: 'warning', onHideCallback: () {
            //debugPrint('..................entrando......................');
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => Theme(
                  data: Theme.of(context), // Hereda el tema actual
                  child: const BLEMainScreen(),
                ),
              ),
            )
                .then((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          });
          // setState(() {
          //   _captchaToken = null;
          // });
        }
      } else {
        if (mounted) {
          showSnackBar(error.message, theme: 'error');
        }
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('Unexpected error occurred', theme: 'error');
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

  String _getTurnstileLanguageCode(BuildContext context) {
    final locale = EasyLocalization.of(context)?.locale ?? const Locale('en');
    switch (locale.languageCode) {
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr';
      case 'en':
      default:
        return 'en';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /* languageList.forEach((lang) {
      lang.langName = 'lang.${lang.locale.languageCode}'.tr();
    });*/

    // Ahora podemos acceder al contexto de EasyLocalization
    final locale = EasyLocalization.of(context)?.locale ?? const Locale('en');
    selectedLang = languageList.firstWhere(
      (e) => e.locale.languageCode == locale.languageCode,
      orElse: () => languageList.first,
    );
  }

  @override
  void initState() {
    setState(() {
      super.initState();
      /*selectedLang = languageList.firstWhere(
        (e) => e.locale.languageCode == context.locale.languageCode,
        orElse: () => languageList.first,
      );*/
      //_showPassword = true;
      //_password2Visible = true;
      //_newpasswordVisible = true;
      supabase = SupabaseProvider.getClient(context);
      //authStep = AuthSteps.signIn;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null, // Eliminamos la AppBar
      body: Stack(
        children: [
          // Contenido principal
          BlocBuilder<ConnectivityBloc, ConnectivityState>(
            builder: (context, state) {
              return _buildLoginForm(context, state);
            },
          ),

          // Barra superior personalizada (reemplazo de AppBar)
          Positioned(
            top: MediaQuery.of(context).padding.top, // Respeta el notch
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Selector de idioma
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.transparent,
                    ),
                    child: DropdownButton<Language>(
                      iconSize: 18,
                      elevation: 16,
                      value: selectedLang,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      underline: Container(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        color: Colors.cyan,
                      ),
                      onChanged: (newValue) async {
                        setState(() {
                          selectedLang = newValue!;
                        });
                        context.setLocale(Locale((newValue!.locale.toString())));
                        debugPrint('Locale--------- ${newValue!.locale.toString()}');
                      },
                      items: languageList.map<DropdownMenuItem<Language>>((Language value) {
                        return DropdownMenuItem<Language>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              value.translatedName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Botón de tema oscuro/claro
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      key: ValueKey<bool>(themeProvider.isDarkMode),
                      icon: themeProvider.isDarkMode
                          ? const Icon(Icons.light_mode_rounded, size: 28)
                          : const Icon(Icons.dark_mode_rounded, size: 28),
                      color: themeProvider.isDarkMode ? Colors.amber : Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        themeProvider.setThemeMode(
                          themeProvider.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                        );
                        _controller.refreshToken();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    /*return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Alinea los widgets en la parte superior
          children: <Widget>[
            // Texto "Required!" sin Padding innecesario
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 0, top: 0, right: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Ícono de advertencia
                        // Contenedor con el texto
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100, // Color de fondo
                            borderRadius: BorderRadius.circular(20), // Bordes redondeados
                          ),
                          width: MediaQuery.of(context).size.width * 0.8,
                          margin: EdgeInsets.only(top: 0, left: 20, right: 0),
                          padding: EdgeInsets.fromLTRB(50, 10, 10, 10),

                          // Limita el ancho del contenedor

                          child: DropdownButton<Language>(
                            iconSize: 18,
                            elevation: 16,
                            //icon: Icon(Icons.language_outlined),
                            value: selectedLang,
                            style: const TextStyle(color: Colors.red),
                            underline: Container(
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              color: Colors.cyan,
                            ),
                            onChanged: (newValue) async {
                              setState(() {
                                selectedLang = newValue!;
                              });
                              context.setLocale(Locale((newValue!.locale.toString())));
                              //_controller.refreshToken();
                              debugPrint('Locale--------- ${newValue!.locale.toString()}');
                            },
                            items: languageList.map<DropdownMenuItem<Language>>((Language value) {
                              return DropdownMenuItem<Language>(
                                value: value,
                                child: Text(
                                  value.translatedName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
              builder: (context, state) {
                return _buildLoginForm(context, state);
              },
            ),
          ],
        ),
      ),
    );*/
    /*return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: DropdownButton<Language>(
            iconSize: 18,
            elevation: 16,
            //icon: Icon(Icons.language_outlined),
            value: selectedLang,
            style: const TextStyle(color: Colors.red),
            underline: Container(
              padding: const EdgeInsets.only(left: 4, right: 4),
              color: Colors.cyan,
            ),
            onChanged: (newValue) async {
              setState(() {
                selectedLang = newValue!;
              });
              context.setLocale(Locale((newValue!.locale.toString())));
              //_controller.refreshToken();
              debugPrint('Locale--------- ${newValue!.locale.toString()}');
            },
            items: languageList.map<DropdownMenuItem<Language>>((Language value) {
              return DropdownMenuItem<Language>(
                value: value,
                child: Text(
                  value.translatedName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              );
            }).toList(),
          ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
                key: ValueKey<bool>(themeProvider.isDarkMode),
                icon: themeProvider.isDarkMode
                    ? const Icon(Icons.light_mode_rounded, size: 28)
                    : const Icon(Icons.dark_mode_rounded, size: 28),
                color: themeProvider.isDarkMode ? Colors.amber : Colors.black,
                onPressed: () => {
                      themeProvider.setThemeMode(
                        themeProvider.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                      ),
                      _controller.refreshToken()
                    }),
          ),
        ],
        // backgroundColor: const Color.fromARGB(255, 214, 236, 235),
        //title:
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, state) {
          return _buildLoginForm(context, state);
        },
      ),
    );*/
  }

  Widget _buildLoginForm(BuildContext context, ConnectivityState state) {
    final stepTexts = AuthSteps.getTexts(authStep);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListView(
      padding: const EdgeInsets.only(top: 75, bottom: 15, left: 10, right: 10),
      children: [
        /*Positioned(
          top: 10,
          right: 50,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              key: ValueKey<bool>(themeProvider.isDarkMode),
              icon: themeProvider.isDarkMode
                  ? Icon(Icons.light_mode_rounded, size: 28)
                  : Icon(Icons.dark_mode_rounded, size: 28),
              color: themeProvider.isDarkMode ? Colors.amber : Colors.deepPurple,
              onPressed: () => themeProvider.setThemeMode(
                themeProvider.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              ),
            ),
          ),*/
        /*SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.setThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        ),*/
        Image(
          image: AssetImage('assets/company_logo.png'),
          width: 100,
          height: 150,
        ),
        if (state is ConnectivityOnline) ...[
          Center(
            child: Text(
              stepTexts['title']!,
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
              'login.no_internet'.tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red.shade500),
            )),
            Center(
                child: TextButton.icon(
                    icon: const Icon(Icons.cloud_off_outlined), label: const Text('Offline'), onPressed: null))
          ])
        ],
        if (state is ConnectivityOnline) ...[
          TextFormField(
            enabled: authStep != AuthSteps.reset,
            controller: _emailController,
            decoration: InputDecoration(
              icon: const Icon(Icons.email_outlined),
              //hintText: 'The email address?',
              labelText: 'login.email'.tr(),
            ),
            onChanged: (value) => {
              if (error.containsKey('login'))
                {
                  error.remove('login'),
                  setState(() {}),
                },
              if (value.isNotEmpty) {error.remove('email_empty'), setState(() {})},
              if (_isValidEmail(value)) {error.remove('email_wrong'), setState(() {})},
            },
          ),
          Offstage(
            offstage: authStep != AuthSteps.reset,
            child: TextFormField(
              controller: _codeController,
              decoration:InputDecoration(
                  icon:  const Icon(Icons.security_update_good),
                  //hintText: 'The email address?',
                  labelText: 'login.code'.tr(),
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
            offstage: authStep != AuthSteps.signUp && authStep != AuthSteps.signIn,
            child: ShowHidePasswordField(
              controller: _passwordController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration:  InputDecoration(
                icon: const Icon(Icons.lock_outline),
                labelText: 'login.password'.tr(),
              ),
              onChanged: (value) {
                if (error.containsKey('login')) {
                  error.remove('login');
                  setState(() {});
                }
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
            offstage: authStep != AuthSteps.reset,
            child: ShowHidePasswordField(
              controller: _newpasswordController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: InputDecoration(
                icon: const Icon(Icons.lock_outline),
                labelText: 'login.new_password'.tr(),
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
            offstage: authStep != AuthSteps.signUp,
            child: ShowHidePasswordField(
              controller: _confirmController,
              iconSize: 24,
              visibleOffIcon: Icons.visibility_off_outlined,
              visibleOnIcon: Icons.visibility_outlined,
              hintText: '',
              decoration: InputDecoration(
                icon: const Icon(Icons.lock_outline),
                labelText: 'login.repeat'.tr(),
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
            child: KeyedSubtree(
              key: ValueKey('turnstile_${context.locale.languageCode}_${themeProvider.isDarkMode}'),
              child: CloudflareTurnstile(
                siteKey: '0x4AAAAAAAc8EpaDnPZMolAQ',
                options: _getTurnstileOptions(themeProvider.isDarkMode),
                controller: _controller,
                onTokenReceived: (token) {
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
                  : authStep == AuthSteps.signIn
                      ? _signIn
                      : authStep == AuthSteps.signUp
                          ? _signUpWithEmail
                          : authStep == AuthSteps.forgot
                              ? _signInRecoveryByEmail
                              : authStep == AuthSteps.reset
                                  ? _resetPassword
                                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade500, fixedSize: const Size(150, 10)),
              child: Text(_isLoading ? 'login.loading'.tr() : stepTexts['btn']!),
            ),
          ),
          Offstage(
            offstage: authStep == AuthSteps.signIn,
            child: TextButton(
              onPressed: () => {
                error.clear(),
                setState(() {
                  authStep = AuthSteps.signIn;
                }),
              },
              child: Text('login.sign_in'.tr(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          Offstage(
            offstage: authStep == AuthSteps.signUp,
            child: TextButton(
              onPressed: () => {
                error.clear(),
                setState(() {
                  authStep = AuthSteps.signUp;
                }),
              },
              child: Text('login.no_account'.tr(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          Offstage(
            offstage: authStep == AuthSteps.forgot,
            child: TextButton(
              onPressed: () => {
                error.clear(),
                setState(() {
                  authStep = AuthSteps.forgot;
                })
              },
              child: Text('login.forgot_password'.tr(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
        ],
        Center(
          child: DropdownButton<Language>(
            iconSize: 18,
            elevation: 16,
            //icon: Icon(Icons.language_outlined),
            value: selectedLang,
            style: const TextStyle(color: Colors.red),
            underline: Container(
              padding: const EdgeInsets.only(left: 4, right: 4),
              color: Colors.cyan,
            ),
            onChanged: (newValue) async {
              setState(() {
                selectedLang = newValue!;
              });
              context.setLocale(Locale((newValue!.locale.toString())));
              //_controller.refreshToken();
              //debugPrint('Locale--------- ${newValue!.locale.toString()}');
            },
            items: languageList.map<DropdownMenuItem<Language>>((Language value) {
              return DropdownMenuItem<Language>(
                value: value,
                child: Text(
                  value.translatedName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
