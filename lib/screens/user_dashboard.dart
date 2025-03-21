import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_login.dart';
import '../provider/supabase_provider.dart';
import '../utils/snackbar_helper.dart';
import '../utils/app_colors.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _loading = true;
  late Map userData;
  late Widget titleWidget;
  bool _isDeleting = false;
  int _countdown = 11;
  Timer? _timer;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final StreamSubscription<AuthState> authSubscription;
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;

  void _startCountdown() {
    setState(() {
      _isDeleting = true;
      _countdown = 10;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        /*setState(() {
          _isDeleting = false; 
        });*/
      }
    });
  }

  Future<void> _executeDeleteAction() async {
    late Map message;
    try {
      final resp = await supabase.auth.updateUser(UserAttributes(data: {'pending_delete': true}));
      //.updateUserById(userid, attributes: AdminUserAttributes(userMetadata: ));

      //debugPrint('response: ${resp.user.toString()}');
      //debugPrint('Pending delete status: ${resp.user!.userMetadata!['pending_delete']}');
      if (resp.user?.userMetadata!['pending_delete'] == true) {
        message = {
          'text': 'Your deletion request will be completed within an hour! Your session will close in 5 seconds!',
          'type': 'success'
        };
      } else {
        message = {'text': 'An error was ocurred, try again later!', 'type': 'error'};
      }
    } catch (e) {
      message = {'text': 'An error was ocurred, try again later!', 'type': 'error'};
    }
    // Aquí puedes ejecutar la acción de eliminación
    if (message['type'] == 'success') {
      showSnackBar(
        message['text'],
        theme: message['type'],
        duration: const Duration(seconds: 5),
        onHideCallback: () {
          _signOut();
        },
      );
    } else {
      showSnackBar(
        message['text'],
        theme: message['type'],
        onHideCallback: () {
          setState(() {
            _isDeleting = false;
            _countdown = 11;
          });
        },
      );
    }
  }

  Future<Map> _getOnlineProfile() async {
    /*setState(() {
      _loading = true;
    });*/
    try {
      final userId = supabase.auth.currentUser!.id;
      userData = await supabaseEAS.from('user_profile').select().eq('id', userId).single();
      if (userData['firstname'].runtimeType == Null) {
        userData.remove('firstname');
        userData = {'firstname': '', ...userData};
      }

      if (userData['lastname'].runtimeType == Null) {
        userData.remove('lastname');
        userData = {'lastname': '', ...userData};
      }

      debugPrint('----- userData online: ${userData.toString()}');
      await _storage.delete(key: supabase.auth.currentUser!.id);
      await _storage.write(key: supabase.auth.currentUser!.id, value: json.encode(userData));
      //setState(() {});
      return userData;
    } on PostgrestException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
      userData = {};
      setState(() {});
    } catch (error) {
      /*if (mounted) {
        showSnackBar('Unexpected error occurred', theme: 'error');
      }*/
    } finally {
      /*if (mounted) {
        setState(() {
          _loading = false;
        });
      }*/
    }
    return {};
  }

  /// Called once a user id is received within `onAuthenticated()`
  Future<Map> _getLocalProfile() async {
    /*setState(() {
      _loading = true;
    });*/
    try {
      final data = await _storage.read(key: supabase.auth.currentUser!.id);
      debugPrint('---- Reading Secure Storage');
      //data = jsonDecode(onValue!);

      userData = json.decode(data!) ?? {};
      //userData['firstname'] = 'Loba';
      debugPrint('---userData offline - ${userData.toString()}');
      return userData;
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      /*if (mounted) {
        setState(() {
          _loading = false;
        });
      }*/
    }
    return {};
  }

  Future<void> _signOut() async {
    setState(() {
      _loading = true;
    });
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('Unexpected error occurred', theme: 'error');
      }
    } finally {
      setState(() {
        _loading = true;
      });
    }
  }

  Future<void> accountDelete() async {
    setState(() {
      _loading = true;
    });
    final userId = supabase.auth.currentUser!.id;
    try {
      await supabase.auth.admin
          .updateUserById(userId, attributes: AdminUserAttributes(userMetadata: {'pending_delete': true}));
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('Unexpected error occurred', theme: 'error');
      }
    } finally {
      setState(() {
        _loading = true;
      });
    }
  }

  bool isset(String? value) {
    return value != null && value.isNotEmpty;
  }
  // bool isset(List<String?> values) {
  //   return values.every((value) => value != null && value.isNotEmpty);
  // }

  String avatarLetter(String name, String lastname) {
    String letter = '';
    String tmpName = '';
    String tmpLastname = '';

    if (name.isNotEmpty) {
      tmpName = name.substring(0, 1).toUpperCase();
    }
    if (lastname.isNotEmpty) {
      tmpLastname = lastname.substring(0, 1).toUpperCase();
    }

    if (tmpName.isNotEmpty && tmpLastname.isEmpty) {
      letter = tmpName; // Solo toma la primera letra
    } else if (tmpName.isEmpty && tmpLastname.isNotEmpty) {
      letter = tmpLastname; // Solo toma la primera letra
    } else if (tmpName.isNotEmpty && tmpLastname.isNotEmpty) {
      letter = tmpName + tmpLastname; // Toma las dos letras
    } else {
      // Verifica si currentUser es null
      //final currentUser = supabase.auth.currentUser;
      //if (currentUser != null && currentUser.email != null) {
      letter = "icon";
      //letter = currentUser.email!.substring(0, 2).toUpperCase();
      //} else {
      //letter = "??"; // Valor por defecto si no hay usuario ni email
      //}
    }

    return letter;
  }

  @override
  void initState() {
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage())).then((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        }
      }
    });
    _getLocalProfile().then((localValue) {
      userData = localValue;

      if (userData.isEmpty || (!isset(userData['firstname']) && !isset(userData['lastname']))) {
        titleWidget = Text('${supabase.auth.currentUser!.email?.split('@')[0]}', style: const TextStyle(fontSize: 16));
      } else if (isset(userData['firstname']) && isset(userData['lastname'])) {
        titleWidget = Text('${userData['firstname']} ${userData['lastname']}');
      } else if (!isset(userData['firstname']) && isset(userData['lastname'])) {
        titleWidget = Text('${userData['lastname']}');
      } else {
        titleWidget = Text('${userData['firstname']}');
      }
      if (userData.isEmpty || (userData['firstname'] == null && userData['lastname'] == null)) {
        // get online profile
        _getOnlineProfile().then((onlineValue) {
          userData = onlineValue;
          if (userData.isEmpty || (!isset(userData['firstname']) && !isset(userData['lastname']))) {
            titleWidget =
                Text('${supabase.auth.currentUser!.email?.split('@')[0]}', style: const TextStyle(fontSize: 16));
          } else if (isset(userData['firstname']) && isset(userData['lastname'])) {
            titleWidget = Text('${userData['firstname']} ${userData['lastname']}');
          } else if (!isset(userData['firstname']) && isset(userData['lastname'])) {
            titleWidget = Text('${userData['lastname']}');
          } else {
            titleWidget = Text('${userData['firstname']}');
          }
          setState(() {
            _loading = false;
          });
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.blue, width: 1.5), borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue.shade100,
                  child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.shade100,
                        child: ((userData['firstname'] == null && userData['lastname'] == null) ||
                                avatarLetter(userData['firstname'], userData['lastname']) == 'icon')
                            ? const Icon(Icons.person)
                            : Text(avatarLetter(userData['firstname'], userData['lastname'])),
                      ),
                      subtitle: /*userData.isEmpty
                          ? */
                          Text(
                        '${supabase.auth.currentUser!.email}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      //: null,
                      title: titleWidget),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                    onPressed: _signOut, label: const Text('Sign Out'), icon: const Icon(Icons.exit_to_app_outlined)),
                const SizedBox(
                  height: 200,
                ),
                Offstage(
                  offstage: !_isDeleting,
                  child: const Center(
                      child: Icon(
                    Icons.warning_amber_sharp,
                    color: Colors.red,
                    size: 60,
                  )),
                ),
                Offstage(
                  offstage: !_isDeleting,
                  child: const Center(
                      child:
                          Text('Are you sure you want to delete your account?', style: TextStyle(color: Colors.red))),
                ),
                Offstage(
                  offstage: _isDeleting,
                  child: TextButton.icon(
                      onPressed: _startCountdown,
                      label: const Text(
                        'Delete account',
                        style: TextStyle(color: Colors.red),
                      ),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      )),
                ),
                Column(
                  children: [
                    Offstage(
                      offstage: (_countdown == 0 || _countdown == 11),
                      child: ElevatedButton(
                        onPressed: null, // Botón deshabilitado
                        child: Text('Confirmar ($_countdown s)'),
                      ),
                    ),
                    Offstage(
                      offstage: _countdown != 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isDeleting = false;
                                  _countdown = 11;
                                }); // Ejecutar la acción al confirmar
                              },
                              label: const Text(
                                'cancel',
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.blue,
                              )),
                          TextButton.icon(
                              onPressed: _executeDeleteAction,
                              label: const Text(
                                'confirm',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      backgroundColor: AppColors.body,
    );
  }
}
