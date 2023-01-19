import 'dart:async';

import 'package:flutter/material.dart';

class GameModel {
  static const int intialTime = 60 * 5; // 5 minutes
  static const int _scorePerGuess = 1;
  final _words = ["dog", "cat", "bear"];
  int _score = 0;
  int _countDown = 0;
  bool _isPlaying = false;
  final Map<int, String> _guessedWords = {};

  GameModel() {
    _countDown = intialTime;
  }

  int get score => _score;
  bool get isPlaying => _isPlaying;
  int get countDown => _countDown;
  Map<int, String> get guessedWords => _guessedWords;

  void guess(String word) {
    final wordToCheck = word.toLowerCase();
    final didGuess = _words.contains(wordToCheck);
    _score += didGuess ? _scorePerGuess : 0;
    if (didGuess) {
      _guessedWords[_words.indexOf(wordToCheck)] = word;
    }
  }

  void newSession() {
    _isPlaying = true;
  }

  void endSession() {
    _isPlaying = false;
    _countDown = intialTime;
    _score = 0;
    _guessedWords.clear();
  }

  void decrementCounter({required int by}) {
    _countDown -= by;
  }

  bool timeEnded() {
    return _countDown <= 0;
  }

  bool hasWon() {
    return _score == _scorePerGuess * _words.length;
  }

  bool hasLoose() {
    return _countDown <= 0 && !hasWon();
  }
}

abstract class InputEvent {}

class InitEvent implements InputEvent {}

class PlayInputEvent implements InputEvent {
  PlayInputEvent();
}

class NewWordInputEvent implements InputEvent {
  final String word;

  NewWordInputEvent(this.word);
}

class TickInputEvent implements InputEvent {
  final int tickAmmount;

  TickInputEvent(this.tickAmmount);
}

class ResetInputEvent implements InputEvent {
  ResetInputEvent();
}

class GameInteractor {
  final GameModel _game;

  final StreamController<GameModel> _outputController = StreamController();
  Stream<GameModel> get output => _outputController.stream;

  final StreamController<InputEvent> _inputController = StreamController();
  StreamSink<InputEvent> get input => _inputController.sink;

  GameInteractor({required GameModel game}) : _game = game {
    _inputController.stream.listen((event) {
      if (event is InitEvent) {
        _outputController.add(_game);
      } else if (event is PlayInputEvent) {
        _game.newSession();
        _outputController.add(_game);
      } else if (event is NewWordInputEvent) {
        _game.guess(event.word);
        _outputController.add(_game);
      } else if (event is TickInputEvent) {
        _game.decrementCounter(by: event.tickAmmount);
        _outputController.add(_game);
      } else if (event is ResetInputEvent) {
        _game.endSession();
        _outputController.add(_game);
      }
    });
  }

  void dispose() {
    _outputController.close();
    _inputController.close();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _textInputController = TextEditingController();
  final GameInteractor interactor = GameInteractor(game: GameModel());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    interactor.input.add(InitEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the word'),
      ),
      // TODO have a more grained output to avoid updating widgets that do not need to update.
      body: StreamBuilder(
          stream: interactor.output,
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const SizedBox();
            }
            return Column(
              children: [
                _headerWidget(game: snapshot.data!),
                const SizedBox(height: 16),
                _sheet(game: snapshot.data!),
                const SizedBox(height: 16),
                _wonLoose(game: snapshot.data!)
              ],
            );
          }),
    );
  }

  Widget _wonLoose({required GameModel game}) {
    final resetButton = TextButton(
      child: const Text('Reset'),
      onPressed: () => interactor.input.add((ResetInputEvent())),
    );
    if (game.hasWon()) {
      _timer?.cancel();
      return Column(
        children: [const Text('You won'), resetButton],
      );
    }
    if (game.hasLoose()) {
      _timer?.cancel();
      return Column(
        children: [const Text('You loose'), resetButton],
      );
    }
    return const SizedBox();
  }

  Widget _sheet({required GameModel game}) {
    // TODO dynamically build the grid based on game words to guess.
    return Column(
      children: [
        Container(
          color: Colors.amber,
          width: 200,
          child:
              Text(game.guessedWords[0] != null ? game.guessedWords[0]! : ""),
        ),
        const SizedBox(
          width: 200,
          height: 4,
        ),
        Container(
          color: Colors.amber,
          width: 200,
          child:
              Text(game.guessedWords[1] != null ? game.guessedWords[1]! : ""),
        ),
        const SizedBox(
          width: 200,
          height: 4,
        ),
        Container(
          color: Colors.amber,
          width: 200,
          child:
              Text(game.guessedWords[2] != null ? game.guessedWords[2]! : ""),
        ),
      ],
    );
  }

  Widget _headerWidget({required GameModel game}) {
    return Row(
      children: [
        game.isPlaying
            ? SizedBox(
                width: 200,
                child: TextField(
                  controller: _textInputController,
                  onSubmitted: (value) =>
                      interactor.input.add(NewWordInputEvent(value)),
                ),
              )
            : TextButton(
                onPressed: () {
                  interactor.input.add(PlayInputEvent());
                  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    interactor.input.add(TickInputEvent(1));
                  });
                },
                child: const Text('Play'),
              ),
        const Spacer(),
        Row(
          children: [
            Column(
              children: [
                const Text('Score'),
                Text('${game.score}'),
              ],
            ),
            Column(
              children: [const Text('Time'), Text('${game.countDown}')],
            ),
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    interactor.dispose();
    super.dispose();
  }
}
