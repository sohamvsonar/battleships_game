import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'playgame.dart';
class CompletedGamesPage extends StatefulWidget {
  final String accessToken;
  final String username;
  CompletedGamesPage({required this.accessToken, required this.username});

  @override
  _CompletedGamesPageState createState() => _CompletedGamesPageState();
}

class _CompletedGamesPageState extends State<CompletedGamesPage> {
  List<Game> completedGames = [];

  @override
  void initState() {
    super.initState();
    // Fetch completed games when the page is loaded
    _fetchCompletedGames();
  }

  Future<void> _fetchCompletedGames() async {
    try {
      final response = await http.get(
        Uri.parse('http://165.227.117.48//games'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        // Parse the response and update the completedGames list
        List<Game> fetchedCompletedGames = [];
        var gamesData = jsonDecode(response.body)['games'];
        for (var gameData in gamesData) {
          fetchedCompletedGames.add(Game.fromJson(gameData));
        }

        setState(() {
          // Filter out active games
          completedGames = fetchedCompletedGames
              .where((game) =>
                  game.status == 1 || game.status == 2) // Completed game statuses
              .toList();
        });
      } else {
        // Handle error response from the server
        print('Error fetching completed games: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error fetching completed games: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Completed Games'),
      ),
      body: ListView.builder(
        itemCount: completedGames.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayGame(gameId: completedGames[index].id, accessToken: widget.accessToken, username: widget.username),
                    ),
                  );
            },
            child: Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('Game ID: ${completedGames[index].id}'),
                subtitle:Row(
                  children: [
                    Flexible(
                      child: Text('${completedGames[index].player1}  vs'),
                    ),
                    SizedBox(width: 16.0),          
                    Flexible(
                      child: Text('${completedGames[index].player2 ?? 'Waiting for opponent'}'),
                    ),
                    SizedBox(width: 16),
                    Flexible(
                      child:Text('${_getStatusText(completedGames[index].status)}'),
                    ),
                  ],
                ), 

              ),
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Player 1 won';
      case 2:
        return 'Player 2 won';
      default:
        return 'Unknown';
    }
  }
}

class Game {
  final int id;
  final String player1;
  final String? player2;
  final int status;

  Game({required this.id, required this.player1, required this.player2, required this.status});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      player1: json['player1'],
      player2: json['player2'],
      status: json['status'],
    );
  }
}
