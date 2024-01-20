# Battleships Game

Battleships Game is a mobile game developed using Flutter and Dart. It allows users to play Battleships against each other on a server or against AI. Battleships is basically a strategy game played between two players. The game is played on grids where there are users ships placed on some grids and the opponents ships on some grids. The game starts once both the players choose the location of their initital 5 ships. Each player plays a turn and waits for the opponent to play its turn, this continues until one of the players all 5 ships are destroyed and the other player wins the game. There are three difficulties against AI(bot) - Random, Perfect and Oneship, Overall it's a fun game to play.

## Table of Contents
- [Specifications](#specifications)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Specifications
Specifications are further classified into features, and detailed behavioral and implementation requirements.

### Feature Overview
- Play Battleships against other players or AI.
- View completed games.
- User authentication and authorization.
- Keeping track of session tokens across application restarts, and requiring users to log in again after their session tokens expire.
- List of live games and completed games played by the user.
- Logging in and registering new users

### Behavioral Specifications

#### Login and Registration

The login screen allows the user to enter their username and password, and to log in to the application. If the user does not have an account, they may also register for a new account from this screen. After logging in or registering, the session token returned by the server should be stored locally and used to authenticate all subsequent requests to the server. If the session token expires, the user should be required to log in again.

#### Game List

The game list page displays, by default, a list of all games that are either in the matchmaking or active state. A manual pull down refresh feature is provided to allow the user to refresh the list of games.

#### New Game

When starting a new game, the user is prompted to place their ships on the board. In our version of Battleships, the game board is 5x5 tiles in dimension, and each ship occupies a single tile. To start a game, the user must place 5 separate ships on the board.

After submitting their ships to start a game, the user returns to the game list page, which should now show the new game in the list of active games retrieved from the server.

#### Playing a Game

The game view page displays the game board, and allows the user to play the game if it is their turn. The game board visually displays the following information:

- the locations of the user's ships
- the locations of the user's ships that have been hit by the opponent
- the locations of the user's shots that missed
- the locations of the user's shots that hit an enemy ship

If it is the user's turn, the user is able to play a shot by tapping on the board to select a location, and submitting it to the server with another button/action. If the shot hits an enemy ship, the user is be able to see the location of the ship that was hit. If the shot misses, the user is be able to see the location of the shot that missed. If the shot wins the game for the user, the user gets notified that they have won the game.

In a human vs. human game, after playing a shot the user will not be able to play again until after the opponent has played. This may require the user to return to the game list page and refresh the list of games to see the updated game status before tapping on the game again.

In a human vs. AI game, so long as the user does not win the game, the AI will immediately update the game state with a follow-up shot after the user plays a shot. The application fetches the updated game state and allow the user to play again.

#### Battleships REST API

The Battleships REST API service can be reached at the base-URL `http://165.227.117.48` (note, this is not a secure connection, so don't use passwords that you're worried about being compromised!). The API is documented below -- all routes that require body content only accept JSON data, and all responses are JSON objects. Route names are prefixed with the corresponding HTTP method:

#### Authentication

- `POST base-URL/register`: Registers a new user. The JSON request body should contain the following fields:
  - `username`: The username of the new user.
  - `password`: The password of the new user.

  Both username and password must be at least 3 characters long and cannot contain spaces. If the username is not already taken, the server will respond with a JSON object containing the following fields:

  - `message`: A message indicating that the user was successfully created.
  - `access_token`: A string containing the user's access token. This token should be included in subsequent requests to API calls that require it. Tokens expire after 1 hour, and must be refreshed by logging in again.

- `POST base-URL/login`: Logs in an existing user. The JSON request body should contain the following fields:
  - `username`: The username of the user to log in.
  - `password`: The password of the user to log in.

  If the username and password are correct, the server will respond with a JSON object containing the following fields:

  - `message`: A message indicating that the user was successfully logged in.
  - `access_token`: A string containing the user's access token. This token should be included in subsequent requests to API calls that require it. Tokens expire after 1 hour, and must be refreshed by logging in again.

#### Managing Games

For all the routes in this section, the HTTP request header should contain the field named "`Authorization`", with the value "`Bearer <access_token>`", where `<access_token>` is the access token returned by the server when the user logged in. If the access token is missing or invalid, the server will respond with a `401 Unauthorized` error, which means that a new token must be obtained by logging in again.

All successful operations will result in an HTTP status code of `200`.

- `GET base-URL/games`: Retrieves all games (active and completed) for one user.

  - The server will respond with a JSON object containing the field `games`, whose value is a list of JSON objects representing the games. Each game object contains the following fields:

    - `id`: The unique ID of the game.
    - `player1`: The username of the player in position 1.
    - `player2`: The username of the player in position 2.
    - `position`: The position of the user in the game (either `1` or `2`).
    - `status`: The status of the game, which can be one of the following values:
      - `0`: The game is in the matchmaking phase.
      - `1`: The game has been won by player 1.
      - `2`: The game has been won by player 2.
      - `3`: The game is actively being played.
    - `turn`: If the game is active, then the position of the player whose turn it is (either `1` or `2`); if the game is not active, `0`.
  
- `POST base-URL/games`: Starts a game with the provided ships. The JSON request body should contain the following fields:

  - `ships`: a list of 5 unique ship locations, each of which is a string of the form "`<row><col>`", where `<row>` is a letter between `A` and `E` and `<col>` is a number between `1` and `5`. For example, the string "`A1`" represents the top-left corner of the board, and the string "`E5`" represents the bottom-right corner of the board.
  - `ai`: (optional) one of the strings "`random`", "`perfect`", or "`random`", which select an AI opponent to play. If omitted, the server will match the user with another human player.
  - e.g., some sample request bodies:
    - `{ "ships": ["A1", "A2", "A3", "A4", "A5"] }`
    - `{ "ships": ["B1", "A2", "D3", "C4", "E5"], "ai": "random" }`

  If the request is successful, the server will respond with a JSON object containing the following fields:

  - `id`: the unique ID of the game
  - `player`: the position of the user in the game (either `1` or `2`)
  - `matched`: `True` if the user was matched with another human player, or if the game is against an AI opponent; `False` if the game is waiting for a human opponent.

- `GET base-URL/games/<game_id>`: Gets detailed information about a game with the integer id `<game_id>`. The server will respond with a JSON object containing the following fields:

  - `id`: The unique ID of the game.
  - `status`: The status of the game, which can be one of the following values:
    - `0`: The game is in the matchmaking phase.
    - `1`: The game has been won by player 1.
    - `2`: The game has been won by player 2.
    - `3`: The game is actively being played.
  - `position`: The position of the user in the game (either `1` or `2`).
  - `turn`: If the game is active, then the position of the player whose turn it is (either `1` or `2`); if the game is not active, `0`.
  - `player1`: The username of the player in position 1.
  - `player2`: The username of the player in position 2.
  - `ships`: a list of coordinates of remaining ships (of the form `A1`, `E5`, etc.) belonging to the user
  - `wrecks`: a list of coordinates of wrecked ships belonging to the user
  - `shots`: a list of shot coordinates previously played by the user, excluding those that successfully hit a ship
  - `sunk`: a list of shot coordinates previously played by the user that hit an enemy ship

- `PUT base-URL/games/<game_id>`: Plays a shot in the game with the integer id `<game_id>`. The JSON request body should contain the following field:

  - `shot`: a string of the form "`<row><col>`", where `<row>` is a letter between `A` and `E` and `<col>` is a number between `1` and `5`.

  If the request is successful, the server will respond with a JSON object containing the following fields:

  - `message`: a message indicating that the shot was played successfully
  - `sunk_ship`: `True` if the shot hit an enemy ship, `False` otherwise.
  - `won`: `True` if the shot won the game for the user, `False` otherwise.

- `DELETE base-URL/games/<game_id>`: Cancels/Forfeits the game with the integer id `<game_id>`. Note that only games which are currently in the matchmaking or active states can be canceled/forfeited. The server will respond with a JSON object containing the following field:

  - `message`: a message indicating that the game was successfully canceled or forfeited.


## Screenshots

![](https://github.com/sohamsonar427/battleships_game/blob/main/lib/Screenshots/LoginSS.jpg)

![](https://github.com/sohamsonar427/battleships_game/blob/main/lib/Screenshots/GameSS.jpg)


## Getting started
### Prerequisites
- Flutter installed. [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)

### Installation
1. Clone the repository.
   ```bash
   git clone https://github.com/sohamvsonar/battleships_game.git

2. External packages

I have included the following packages in the `pubspec.yaml` file:

- [`http`](https://pub.dev/packages/http): a library that provides a set of high-level asynchronous functions for communicating with HTTP servers
- [`shared_preferences`](https://pub.dev/packages/shared_preferences): a library that provides a persistent store for simple data
- [`provider`](https://pub.dev/packages/provider): a library that provides a set of utilities for managing and disseminating stateful data

3. Install dependencies
    ```bash
    flutter pub get

## Usage

1. Run the app
    ```bash
    flutter run

2. Play Battleships and enjoy the game!

## License

This project is licensed under the MIT License.
