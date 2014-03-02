import 'package:angular/angular.dart';
import 'dart:math';
import 'dart:core';
import 'dart:async';
import 'dart:html' as dom;

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(override: '*')
import 'dart:mirrors';

@NgController(selector: '[gameCtrl]', publishAs: 'ctrl')
class GameController {

  static const int LEFT_ARROW = 37;
  static const int UP_ARROW = 38;
  static const int DOWN_ARROW = 40;
  static const int RIGHT_ARROW = 39;
  static const int SPACE = 32;

  final Random r = new Random();
  final Duration defaultDuration = new Duration(milliseconds: 500);
  final List<Button> buttons = [Button.BLUE, Button.GREEN, Button.YELLOW, Button.RED];
  final List<Button> sequence = [];
  final List<Button> listeningSequence = [];

  State state;
  String header;
  bool showCheckMark;

  GameController() {
    state = State.IDLE;
    showCheckMark = false;
  }

  void start() {
    sequence.clear();
    nextLevel();
  }

  void nextLevel() {
    sequence.add(nextRandomButton());
    new Future.delayed(defaultDuration, () {
      showCheckMark = false;
      playSequence(sequence);
    });
  }

  void gameOver() {
    inactivateAll();
    state = State.GAME_OVER;
  }

  void playSequence(List<Button> sequence) {
    state = State.PLAYING;
    inactivateAll();
    Button head = sequence.first;
    List<Button> tail = sequence.sublist(1, sequence.length);
    Completer completer = new Completer();
    new Future.delayed(defaultDuration, () {
      recursivelyPlayButtons(completer, head, tail);
    });
    completer.future.whenComplete(() {
      inactivateAll();
      listenForSequence(sequence);
    });
  }

  /**
   * Plays first button ('head') and recursively schedules playing of remaining buttons ('tail').
   * Completes 'completer' when all buttons have been played (empty 'tail').
   */

  void recursivelyPlayButtons(Completer completer, Button head, List<Button> tail) {
    head.active = true;
    new Future.delayed(defaultDuration, () {
      head.active = false;
    }).then((_) {
      if (tail.isEmpty) {
        new Future.delayed(defaultDuration, () => completer.complete());
      } else {
        Button newHead = tail.first;
        List<Button> newTail = tail.sublist(1, tail.length);
        new Future.delayed(defaultDuration, () => recursivelyPlayButtons(completer, newHead, newTail));
      }
    });
  }

  void listenForSequence(List<Button> sequence) {
    state = State.LISTENING;
    listeningSequence.clear();
    listeningSequence.addAll(sequence.reversed);
  }

  Button nextRandomButton() => buttons[r.nextInt(4)];

  void onKeyUp(dom.KeyboardEvent event) {
    if (isInputEnabled()) {
      switch (event.keyCode) {
        case LEFT_ARROW:
          onClick(Button.BLUE);
          break;
        case UP_ARROW:
          onClick(Button.GREEN);
          break;
        case DOWN_ARROW:
          onClick(Button.YELLOW);
          break;
        case RIGHT_ARROW:
          onClick(Button.RED);
          break;
        case SPACE:
          if (mayStart()) start();
          break;
        default: // ignore all others
      }
      new Future.delayed(defaultDuration, () => inactivateAll());
    }
  }

  bool onClick(Button b) {
    if (isInputEnabled()) {
      b.active = true;
      if (isListening()) {
        Button last = listeningSequence.removeLast();
        if (last != b) {
          gameOver();
        } else if (listeningSequence.isEmpty) {
          new Future.delayed(defaultDuration, () => showCheckMark = true).then((_) => nextLevel());
        }
      }
    }
  }

  bool isInputEnabled() => State.INPUT_ENABLED_STATES.contains(state);
  bool isListening() => State.LISTENING == state;
  bool mayStart() => State.IDLE == state || State.GAME_OVER == state;

  void inactivateAll() => buttons.forEach((b) {
    b.active = false;
  });

}

class Button {

  static final BLUE = new Button("blue", "\u2190");
  static final GREEN = new Button("green", "\u2191");
  static final YELLOW = new Button("yellow", "\u2193");
  static final RED = new Button("red", "\u2192");

  final String color;
  final String keyBinding;
  bool active;

  Button(this.color, this.keyBinding);

  String toString() => color;

}

class State {
  static const IDLE = const State._("Start");
  static const PLAYING = const State._("Beobachten...");
  static const LISTENING = const State._("Nachspielen!");
  static const GAME_OVER = const State._("Ooops... Neues Spiel?");

  static const List<State> INPUT_ENABLED_STATES = const [IDLE, LISTENING, GAME_OVER];

  final String description;

  const State._(this.description);
}

class SimonSaysModule extends Module {
  SimonSaysModule() {
    type(GameController);
  }
}

main() {
  ngBootstrap(module: new SimonSaysModule());
}