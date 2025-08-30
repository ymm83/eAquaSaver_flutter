import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../provider/supabase_provider.dart';
import '../utils/snackbar_helper.dart';
import 'user_dashboard.dart';
import 'reviews_screen.dart';
import 'account_screen.dart';
import 'issue_screen.dart';
import 'issue_form.dart';

class UserTabs extends StatefulWidget {
  const UserTabs({super.key});

  @override
  State<UserTabs> createState() => _UserTabsState();
}

class _UserTabsState extends State<UserTabs> {
  final PageController _userTabController = PageController(keepPage: true);
  int _currentPage = 0;
  String _pageTitle = 'Profile';
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;
  late ConnectivityBloc connectivityBloc;

  @override
  void initState() {
    connectivityBloc = BlocProvider.of<ConnectivityBloc>(context);
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);

    super.initState();
  }

  void connectionOffMessage(BuildContext c) {
    showSnackBar('You are offline!', context: c, theme: 'error', icon: Icons.cloud_off_outlined);
  }

  void _navigateToPage(int page) {
    debugPrint('Navegando a la página: $page');
    if (connectivityBloc.state is ConnectivityOnline) {
      _userTabController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      connectionOffMessage(context);
    }
  }

  List<Widget> _actionsDefault(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.manage_accounts_outlined,
          color: Colors.blue[900],
          size: 30,
        ),
        onPressed: () => _navigateToPage(1),
      ),
      IconButton(
        icon: Icon(
          Icons.reviews_outlined,
          color: Colors.blue[900],
          size: 30,
        ),
        onPressed: () => _navigateToPage(2),
      ),
      IconButton(
        icon: Icon(
          Icons.bug_report_outlined,
          color: Colors.blue[900],
          size: 30,
        ),
        onPressed: () => _navigateToPage(3),
      ),
    ];
  }

  List<Widget> _actionsIssue(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.checklist_outlined,
          color: Colors.blue[900],
          size: 30,
        ),
        onPressed: () => _navigateToPage(3),
      ),
      IconButton(
        icon: Icon(
          Icons.add_box_outlined,
          color: Colors.blue[900],
          size: 30,
        ),
        onPressed: () => _navigateToPage(4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            Container(
              color: Theme.of(context).appBarTheme.backgroundColor, // Color de fondo del AppBar
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Botón de retroceso (back)
                  if (_currentPage > 0)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_outlined,
                        color: Colors.blue[900],
                        size: 30,
                      ),
                      onPressed: () => _navigateToPage(0),
                    ),
                  // Título de la página
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 0), // Ajusta el padding si es necesario
                      child: Text(
                        _pageTitle,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.blue.shade900),
                      ),
                    ),
                  ),
                  // Acciones del AppBar
                  if (_currentPage == 0) ..._actionsDefault(context),
                  if ([3, 4, 5].contains(_currentPage)) ..._actionsIssue(context),
                ],
              ),
            ),
            // Contenido de la página
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                //pageSnapping: false,
                controller: _userTabController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _pageTitle = ['Dashboard', 'Profile', 'Reviews', 'My issues', 'New issue', 'Edit issue'][index];
                  });
                },
                children: [
                  const UserDashboard(),
                  const AccountScreen(),
                  ReviewsScreen(onNavigate: _navigateToPage),
                  IssueScreen(onNavigate: _navigateToPage),
                  IssueForm(typeForm: 'new', onNavigate: _navigateToPage),
                  IssueForm(typeForm: 'edit', onNavigate: _navigateToPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
