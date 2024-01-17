import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlayGame extends StatefulWidget {
  final int gameId;
  final String accessToken;
  final String username;

  PlayGame({required this.gameId, required this.accessToken, required this.username});

  @override
  _PlayGameState createState() => _PlayGameState();
}

class _PlayGameState extends State<PlayGame> {
  List<List<bool>> grid = List.generate(5, (_) => List.filled(5, false));
  List<String> shipLocations = [];
  int shipsPlaced = 0;
  int selectedRow = -1;
  int selectedCol = -1;
  int turn = 0; 
  String player1 = ''; 
  String player2 = '';
  List<String> shotCoordinates = [];
  List<String> sunkShipCoordinates = [];
  List<String> wreckShipsCoordinates = [];
  @override
  void initState() {
    super.initState();
    // Fetch the initial ship locations when the page is loaded
    _fetchShipLocations();
  }

  Future<void> _fetchShipLocations() async {
    try {
      final response = await http.get(
        Uri.parse('http://165.227.117.48/games/${widget.gameId}'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response and update the shipLocations list
        List<String> fetchedShipLocations = [];
        List<String> fetchedShotCoordinates = [];
        List<String> fetchedSunkShipCoordinates = [];
        List<String> fetchedwreckShipsCoordinates = [];

        var gameData = jsonDecode(response.body);
        for (var shipLocation in gameData['ships']) {
          fetchedShipLocations.add(shipLocation);
        }
        if (gameData.containsKey('shots')) {
          for (var shotCoordinate in gameData['shots']) {
            fetchedShotCoordinates.add(shotCoordinate);
          }
        }
        if (gameData.containsKey('sunk')) {
          for (var sunkShipCoordinate in gameData['sunk']) {
            fetchedSunkShipCoordinates.add(sunkShipCoordinate);
          }
        }
        if (gameData.containsKey('wrecks')) {
          for (var wreckShipsCoordinates in gameData['wrecks']) {
            fetchedwreckShipsCoordinates.add(wreckShipsCoordinates);
          }
        }
        setState(() {
          shipLocations = fetchedShipLocations;
          shotCoordinates = fetchedShotCoordinates;
          sunkShipCoordinates = fetchedSunkShipCoordinates;
          wreckShipsCoordinates = fetchedwreckShipsCoordinates;
          turn = gameData['turn'];
          player1 = gameData['player1'];
          player2 = gameData['player2'] ?? '';
        });
      } else {
        // Handle error response from the server
        print('Error fetching ship locations: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error fetching ship locations: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game ID: ${widget.gameId}'),
      ),
      body: Column(
        children: [
          _buildGameBoard(),
          ElevatedButton(
            onPressed: (turn == 1 && player1 == widget.username && player2.isNotEmpty)? () => _submitMove():
            (turn == 2 && player2 == widget.username && player2.isNotEmpty)? () => _submitMove(): null,
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
                    if (shipLocations.isEmpty) {
                      _showLoseDialog();
                    }
                    if (player2.isEmpty) {
                      // Show a snackbar if it's the opponent's turn
                      _showSnackbar("Waiting for Opponent");
                    }
                    else if (turn == 1 && player1 == widget.username)  {
                      // Deselect the previously selected grid
                      if (selectedRow != -1 && selectedCol != -1) {
                        grid[selectedRow - 1][selectedCol - 1] = false;
                      }

                      // Toggle the current grid state
                      grid[row - 1][col - 1] = !grid[row - 1][col - 1];
                      shipsPlaced = _countShips();

                      // Update the selected coordinates
                      selectedRow = row;
                      selectedCol = col;
                    } else if (turn == 2 && player2 == widget.username)  {
                      // Deselect the previously selected grid
                      if (selectedRow != -1 && selectedCol != -1) {
                        grid[selectedRow - 1][selectedCol - 1] = false;
                      }

                      // Toggle the current grid state
                      grid[row - 1][col - 1] = !grid[row - 1][col - 1];
                      shipsPlaced = _countShips();

                      // Update the selected coordinates
                      selectedRow = row;
                      selectedCol = col;
                    } else if (turn == 1 && player2 == widget.username) {
                      // Show a snackbar if it's the opponent's turn
                      _showSnackbar("It's Opponent's Turn");
                    } else if (turn == 2 && player1 == widget.username) {
                      // Show a snackbar if it's the opponent's turn
                      _showSnackbar("It's Opponent's Turn");
                    }  

                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: grid[row - 1][col - 1] ? Colors.blue : Colors.white,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [                        
                        if (shipLocations.contains('${String.fromCharCode(row + 64)}${col}'))
                          Icon(Icons.directions_boat, color: Colors.green)
                        else if (wreckShipsCoordinates.contains('${String.fromCharCode(row + 64)}${col}'))
                          Icon(Icons.bubble_chart, color: Colors.blue),                          
                        if (sunkShipCoordinates.contains('${String.fromCharCode(row + 64)}${col}'))
                          Icon(Icons.block, color: Colors.yellow) // Display bolt icon
                        else if (shotCoordinates.contains('${String.fromCharCode(row + 64)}${col}'))
                          Icon(Icons.bolt, color: Colors.red)

                      ],
                    )
                ),
              ),
            );
          } else {
            return Container();
          }
        },
        itemCount: 36, // 6 columns x 6 rows
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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

  void _submitMove() async {
    // Check if exactly 1 shot is placed
    if (_countShips() != 1) {
      _showSnackbar('Please place exactly 1 ship before playing the turn.');
      return;
    }
    // Get the selected coordinates
    String shotLocation = '${String.fromCharCode(selectedRow + 64)}$selectedCol';

    try {
      final response = await http.put(
        Uri.parse('http://165.227.117.48/games/${widget.gameId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: jsonEncode({'shot': shotLocation}),
      );

      if (response.statusCode == 200) {
        // Parse the response
        
        var responseData = jsonDecode(response.body);
        bool sunkShip = responseData['sunk_ship'];
        bool won = responseData['won'];
        if (won) {
          _showVictoryDialog();
        }        
        else if (sunkShip) {
          _showSnackbar('You destroyed a enemy ship');
        }
        // Check if the shot was successful
        else if (responseData['message'] == 'Shot played successfully') {
          // Show Snackbar with the result
          _showSnackbar('Shot played successfully');
        } else {
          
          // Handle other possible responses from the server
          _showSnackbar('Error: ${responseData['message']}');
        }
        _fetchShipLocations();
      } else {
        // Handle error response from the server
        _showSnackbar('Shot already played, Select another location');
      }
    } catch (error) {
      // Handle network error
      print('Error submitting shot: $error');
      _showSnackbar('An error occurred. Please try again.');
    }
    
  }
  void _showVictoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You have won the game.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLoseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hard Luck'),
          content: Text('You have Lost the game.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

}
