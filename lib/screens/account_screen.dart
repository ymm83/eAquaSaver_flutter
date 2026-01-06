import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/supabase_provider.dart';
import '../utils/snackbar_helper.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  var _loading = true;
  bool _isDeleting = false;
  int _countdown = 10;
  Timer? _timer;
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  late StreamSubscription authSubscription;

  void _startCountdown() {
    setState(() {
      _isDeleting = true;
      _countdown = 9;
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
            _countdown = 10;
          });
        },
      );
    }
  }

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabaseEAS.from('user_profile').select().eq('id', userId).single();
      _firstnameController.text = (data['firstname'] ?? '') as String;
      _lastnameController.text = (data['lastname'] ?? '') as String;
      await _storage.write(key: supabase.auth.currentUser!.id, value: json.encode(data));
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
    final firtsname = _firstnameController.text.trim();
    final lastname = _lastnameController.text.trim();
    final userId = supabase.auth.currentUser!.id;
    final updates = {
      'firstname': firtsname,
      'lastname': lastname,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabaseEAS.from('user_profile').update(updates).eq('id', userId);
      if (mounted) {
        showSnackBar('Perfil actualizado con éxito!', theme: 'success');
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        showSnackBar(error.message, theme: 'error');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('Ocurrió un error inesperado', theme: 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    _getProfile();
    authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        //Navigator.of(context).pushReplacementNamed('/login');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                TextFormField(
                  controller: _firstnameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _lastnameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 18),
                UnconstrainedBox(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _updateProfile,
                    icon: Icon(Icons.save_rounded),
                    label: Text(_loading ? 'Saving...' : 'Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                /*Offstage(
                  offstage: !_isDeleting,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_sharp,
                          color: Colors.red,
                          size: 60,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Are you sure you want to delete your account?',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),*/

                Offstage(
                  offstage: !_isDeleting,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: EdgeInsets.only(top: 50),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 40,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Are you sure you want to delete your account?\n'
                                'This action cannot be undone.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isDeleting = false;
                                  _countdown = 10;
                                }); // Ejecutar la acción al confirmar
                              },
                              label: const Text(
                                'cancel',
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.blue,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: (_countdown > 0 && _countdown < 10) ? null : _executeDeleteAction,
                              label: Text(
                                (_countdown > 0 && _countdown < 10) ? '($_countdown)  Delete ' : 'Delete',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              icon: (_countdown > 0 && _countdown < 10)
                                  ? SizedBox()
                                  : Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                Offstage(
                  offstage: _isDeleting,
                  child: UnconstrainedBox(
                    child: ElevatedButton.icon(
                      onPressed: _startCountdown,
                      label: Text(
                        'Delete account',
                        style: TextStyle(color: Colors.red),
                      ),
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondaryFixed,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryFixedVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                    ),
                  ),
                ),
                /*Column(
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
                          OutlinedButton.icon(
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
                              ), style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.blue),
                                ),),
                          OutlinedButton.icon(
                              onPressed: _executeDeleteAction,
                              label: const Text(
                                'confirm',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                               style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),),
                        ],
                      ),
                    ),
                  ],
                ),*/
              ],
            ),
    );
  }
}
