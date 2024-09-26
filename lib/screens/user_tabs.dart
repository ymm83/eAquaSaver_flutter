import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/issue/issue_bloc.dart';
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
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late ConnectivityBloc connectivityBloc;

  @override
  void initState() {
    connectivityBloc = BlocProvider.of<ConnectivityBloc>(context);
    super.initState();
  }

  void connectionOffMessage() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Center(child: Text('You are offline!')),
        backgroundColor: Colors.red,
        showCloseIcon: true,
        duration: Duration(seconds: 2),
      ),
    );
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
    final SupabaseClient supa = BlocProvider.of<IssueBloc>(context).supabase;

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
              ReviewsScreen(supabase: supa, pageController: _userTabController),
              IssueScreen(pageController: _userTabController, supabase: supa),
              IssueForm(typeForm: 'new', supabase: supa, pageController: _userTabController),
              IssueForm(typeForm: 'edit', supabase: supa, pageController: _userTabController),
            ],
          ),
        ));
  }
}
