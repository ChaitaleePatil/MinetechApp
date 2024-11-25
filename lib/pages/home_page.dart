import 'package:flutter/material.dart';
import 'team_list_page.dart'; // If needed

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to your Home Page!', style: TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: () {
                // Go to Team List Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeamListPage()),
                );
              },
              child: Text('View Teams'),
            ),
          ],
        ),
      ),
    );
  }
}
