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
  final PageController _userTabController = PageController(keepPage: false);
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

  void connectionOffMessage() {
    showSnackBar('You are offline!', theme: 'error', icon: Icons.cloud_off_outlined);
  }

  void _navigateToPage(int page) {
    if (connectivityBloc.state is ConnectivityOnline) {
      _userTabController.jumpToPage(page);
    } else {
      connectionOffMessage();
    }
  }

  List<Widget> _actionsDefault(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.manage_accounts_outlined, color: Colors.blue[900]),
        onPressed: () => _navigateToPage(1),
      ),
      IconButton(
        icon: Icon(Icons.reviews_outlined, color: Colors.blue[900]),
        onPressed: () => _navigateToPage(2),
      ),
      IconButton(
        icon: Icon(Icons.bug_report_outlined, color: Colors.blue[900]),
        onPressed: () => _navigateToPage(3),
      ),
    ];
  }

  List<Widget> _actionsIssue(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.checklist_outlined, color: Colors.blue[900]),
        onPressed: () => _navigateToPage(3),
      ),
      IconButton(
        icon: Icon(Icons.add_box_outlined, color: Colors.blue[900]),
        onPressed: () => _navigateToPage(4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            leading: _currentPage > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_outlined),
                    onPressed: () => _navigateToPage(0),
                  )
                : null,
            leadingWidth: 40,
            actions: _currentPage == 0
                ? _actionsDefault(context)
                : ([3, 4, 5].contains(_currentPage))
                    ? _actionsIssue(context)
                    : _actionsDefault(context),
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: Text(_pageTitle),
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            pageSnapping: false,
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
              ReviewsScreen(pageController: _userTabController),
              IssueScreen(pageController: _userTabController),
              IssueForm(typeForm: 'new', pageController: _userTabController),
              IssueForm(typeForm: 'edit', pageController: _userTabController),
            ],
          ),
        ));
  }
}
