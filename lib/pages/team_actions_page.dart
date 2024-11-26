import 'package:flutter/material.dart';
import '../dialogue/create_team.dart';
import '../dialogue/join_team.dart';

class TeamActionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Actions'),
        titleTextStyle: TextStyle(
            color: Colors.blue[400], fontWeight: FontWeight.w700, fontSize: 25),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 175,
              height: 50,
              child: ElevatedButton(
                onPressed: () => showJoinTeamDialog(context),
                child: Text(
                  'Join Team',
                  style: TextStyle(
                    color: Colors.blue[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(
                height: 20), // Add space between the buttons and the "or" text
            Text('-------- OR --------',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[400],
                    fontWeight: FontWeight.w300)),
            SizedBox(height: 20), // Add space after the "or" text
            SizedBox(
              width: 175,
              height: 50,
              child: ElevatedButton(
                onPressed: () => showCreateTeamDialog(context),
                child: Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.blue[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            )
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
