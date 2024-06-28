import 'package:flutter/material.dart';
import 'account_screen.dart';

class UserTabs extends StatefulWidget {
  const UserTabs({super.key});

  @override
  State<UserTabs> createState() => _UserTabsState();
}

class _UserTabsState extends State<UserTabs> {
  @override
  Widget build(BuildContext context) {
    final UserTabsController = DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: const TabBar(
              /* labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  color: Colors.white),
              dividerHeight: 50,
              indicatorColor: Colors.red,*/
              tabs: [
                Tab(
                  icon: Icon(Icons.manage_accounts_outlined),
                ),
                Tab(
                  icon: Icon(Icons.star_half_outlined),
                ),
                Tab(
                  icon: Icon(Icons.comment_outlined),
                ),
                Tab(
                  icon: Icon(Icons.bug_report_outlined),
                )
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AccountScreen(),
              Center(child: Text('Rating')),
              Center(child: Text('Comments')),
              Center(child: Text('Issues')),
            ],
          ),
        ));
    return Scaffold(
      body: UserTabsController,
    );
  }
}
