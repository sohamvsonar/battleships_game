import 'dart:convert';
import '/completedgames.dart';
import 'package:http/http.dart' as http;
import '/gamepage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginpage.dart';
import 'playgame.dart';

class BattleshipsPage extends StatefulWidget {

  final String username;
  final String accessToken;

  BattleshipsPage({required this.username, required this.accessToken});

  @override
  _BattleshipsPageState createState() => _BattleshipsPageState();
}

class _BattleshipsPageState extends State<BattleshipsPage> {
  List<Game> games = [];
  List<String> aiOptions = ['Random AI', 'Perfect AI', 'One ship (A1)'];

  @override
  void initState() {
    super.initState();
    // Fetch the list of games when the page is loaded
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      final response = await http.get(
        Uri.parse('http://165.227.117.48//games'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        
        List<Game> fetchedGames = [];
        var gamesData = jsonDecode(response.body)['games'];
        for (var gameData in gamesData) {
          fetchedGames.add(Game.fromJson(gameData));
        }

        setState(() {
          games = fetchedGames.where((game) => game.status == 0 || game.status == 3).toList();
        });
      } else {
        // Handle error response from the server
        print('Error fetching games: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error fetching games: $error');
    }
  }
  Future<void> _handleLogout() async {
    // Clear the stored token
    await _clearTokenLocally();

    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _clearTokenLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('access_token');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battleships'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: (){
              _fetchGames();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Text(
                      'Battleships Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Logged in as ${widget.username}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('New Game'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameSetupPage(accessToken: widget.accessToken, username: widget.username),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.android),
              title: Text('New Game (AI)'),
              onTap: () {
                _showAIDifficultyDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.games),
              title: Text('Show Completed Games'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompletedGamesPage(accessToken: widget.accessToken, username: widget.username),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGames();
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return GameTile(game: games[index], username: widget.username, accessToken: widget.accessToken, fetchedGames: _fetchGames,);
                },
              ),
            ),
          ],
        ),  
      ),
    );
  }

  void _showAIDifficultyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose difficulty'),
          content: Column(
            children: [
              for (String option in aiOptions)
                ListTile(
                  title: Text(option),
                  onTap: () {
                    _handleAIOption(option);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleAIOption(String selectedOption) {
    
    switch (selectedOption) {
      case 'Random AI':
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameSetupPage(accessToken: widget.accessToken, username: widget.username,ai: "random"),
                  ),
          );
        break;
        
      case 'Perfect AI':
        Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameSetupPage(accessToken: widget.accessToken, username: widget.username,ai: "perfect"),
                ),
        );
        
        break;
      case 'One ship (A1)':
        Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameSetupPage(accessToken: widget.accessToken, username: widget.username,ai: "oneship"),
                ),
        );        
        break;
      default:
        break;
    }

  }
  
}

class GameTile extends StatelessWidget {
  final Game game;
  final String username;
  final String accessToken;
  final Function fetchedGames;
  const GameTile({Key? key, required this.game, required this.username, required this.accessToken, required this.fetchedGames}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String subtitleText = '';

    if (game.status == 3) {
      if (game.turn == 1 && game.player1 == username) {
        subtitleText = 'My Turn';
      } else if (game.turn == 1 && game.player2 == username ) {
        subtitleText = 'Opponent Turn';
      } else if (game.turn == 2 && game.player1 == username) {
        subtitleText = 'Opponent Turn';
      } else if (game.turn == 2 && game.player2 == username) {
        subtitleText = 'My Turn';
      }
    } else {
      subtitleText = _getStatusText(game.status);
    }
    return Dismissible(
      key: Key(game.id.toString()),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _handleForfeit(game.id);
        }
      },
      background: Container(
        color: Colors.red, 
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(
            Icons.cancel,
            color: Colors.white,
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          title: Text('Game ID: ${game.id}',
          style: TextStyle(fontSize: 14.0),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child:Text('${game.player1}    vs',
                style: TextStyle(fontSize: 15.0),
                ),
              ),
              SizedBox(width: 16.0),
              Flexible(
                child: Text('${game.player2 ?? 'Waiting for opponent'}',
                style: TextStyle(fontSize: 15.0),
                ),
              ),
              Spacer(flex: 2),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('$subtitleText',
                  style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
            ],
          ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayGame(gameId: game.id, accessToken: accessToken, username: username),
                ),
              );
            },
        ),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Matchmaking';
      case 1:
        return 'Player 1 won';
      case 2:
        return 'Player 2 won';
      case 3:
        return 'Active';
      default:
        return 'Unknown';
    }
  }

  void _handleForfeit(int gameId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://165.227.117.48/games/$gameId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        print('Game $gameId forfeited successfully.');
        fetchedGames();
      } else {
        // Handle error response from the server
        print('Error forfeiting game $gameId: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error forfeiting game $gameId: $error');
    }
  }

 
}

class Game {
  final int id;
  final String player1;
  final String? player2;
  final int status;
  final int turn;

  Game({required this.id, required this.player1, required this.player2, required this.status, required this.turn});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      player1: json['player1'],
      player2: json['player2'],
      status: json['status'],
      turn: json['turn'],
    );
  }
}