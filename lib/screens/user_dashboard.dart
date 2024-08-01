import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_login.dart';
import '../main.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  var _loading = true;
  late Map userData;

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      userData = await supabaseEAS.from('user_profile').select().eq('id', userId).single();
    } on PostgrestException catch (error) {
      if (mounted) {
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
      userData = {};
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

  final authSubscription = supabase.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.signedOut) {
      //Navigator.of(context).pushReplacementNamed('/login');
    }
  });

  Future<void> _signOut() async {
    setState(() {
      _loading = true;
    });
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
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
      setState(() {
        _loading = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue.shade200,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Text('YM'),
                    ),
                    title: Text(userData.isNotEmpty ? '${userData['firstname']} ${userData['lastname']}' : ''),
                    subtitle: Text('${supabase.auth.currentUser!.email}'),
                  ),
                ),
                const SizedBox(height: 30),
                Positioned.fill(
                    bottom: 20,
                    child: Center(
                        child: TextButton(
                      onPressed: () {
                        _signOut();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: TextButton.icon(
                          onPressed: _signOut,
                          label: const Text('Sign Out'),
                          icon: const Icon(Icons.exit_to_app_outlined)),
                    )))
              ],
            ),
    );
  }
}
