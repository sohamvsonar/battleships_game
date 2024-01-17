import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'battleshipspage.dart';

class GameSetupPage extends StatefulWidget {
  final String accessToken;
  final String username;
  final String? ai;
  GameSetupPage({required this.accessToken, required this.username, this.ai});

  @override
  _GameSetupPageState createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  List<List<bool>> grid = List.generate(5, (_) => List.filled(5, false));
  int shipsPlaced = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Setup'),
      ),
      body: Column(
        children: [
          _buildGameBoard(),
          ElevatedButton(
            onPressed: () => _startGame(),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    double gridSize = MediaQuery.of(context).size.width / 6;

    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, 
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          int row = index ~/ 6;
          int col = index % 6;

          if (col == 0 && row > 0) {
          // Alphabet labels (A, B, C, D, E)
            return Container(
              width: gridSize,
              child: Center(
                child: Text(String.fromCharCode(row + 64)),
              ),
            );
          } else if (row == 0 && col > 0) {
          // Column labels (1, 2, 3, 4, 5)
            return Container(
              width: gridSize,
              child: Center(
                child: Text('${col}'),
              ),
            );
          } else if (row > 0 && col > 0) {
          // Game board cells
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_countShips() < 5) {
                  // Toggle the grid state
                    grid[row - 1][col - 1] = !grid[row - 1][col - 1];
                    shipsPlaced = _countShips();
                  } else {
                  // If all 5 grids are selected, allow deselection
                    if (grid[row - 1][col - 1]) {
                      grid[row - 1][col - 1] = false;
                      shipsPlaced = _countShips();
                    } else {
                    // Show snackbar if trying to select more than 5 grids
                      _showSnackbar('You can place only up to 5 ships.');
                    }
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  color: grid[row - 1][col - 1] ? Colors.blue : Colors.white,
                ),
                child: Center(
                  child: Text(''),
                ),
              ),
            );
          } else {
            return Container();
          }
        },
        itemCount: 36, 
      ),
    );
  }

  void _startGame({String? ai}) async {
    // Check if exactly 5 ships are placed
    if (_countShips() != 5) {
      _showSnackbar('Please place exactly 5 ships before starting the game.');
      return;
    }

    // Convert the grid to a list of ship locations
    List<String> ships = [];
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (grid[row][col]) {
          ships.add('${String.fromCharCode(row + 65)}${col + 1}');
        }
      }
    }

    // Prepare the request body
    Map<String, dynamic> requestBody = {
      'ships': ships,
    };
    if(widget.ai != null){
      requestBody['ai'] = widget.ai;
    }

    // Send the request to start the game
    try {
      final response = await http.post(
        Uri.parse('http://165.227.117.48/games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Game started successfully, navigate to the BattleshipsPage
        Navigator.of(context).pop(); // Close GameSetupPage
        _showSnackbar('Game started successfully.');

        // Navigate to the BattleshipsPage and refresh the games list
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BattleshipsPage(username: widget.username,accessToken: widget.accessToken)),
        );
      } else {
        // Handle error response from the server
        _showSnackbar('Error starting the game. Please try again.');
      }
    } catch (error) {
      print('Error: $error');
      _showSnackbar('An error occurred. Please try again.');
    }
  }

  int _countShips() {
    int count = 0;
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (grid[row][col]) {
          count++;
        }
      }
    }
    return count;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
  
}
