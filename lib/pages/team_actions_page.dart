import 'package:flutter/material.dart';
import '../dialogue/create_team.dart';
import '../dialogue/join_team.dart';

class TeamActionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team Actions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => showJoinTeamDialog(context),
              child: Text('Join Team'),
            ),
            ElevatedButton(
              onPressed: () => showCreateTeamDialog(context),
              child: Text('Create Team'),
            ),
          ],
        ),
      ),
    );
  }

  void showJoinTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return JoinTeamDialog();
      },
    );
  }

  void showCreateTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return CreateTeamDialog();
      },
    );
  }
}
