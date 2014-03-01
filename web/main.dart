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

  final Random r = new Random();
  final Duration defaultDuration = new Duration(milliseconds: 500);

  List<Button> buttons = [];
  final List<Button> sequence = [];
  final List<Button> listeningSequence = [];
  State state;
  String header;

  GameController() {
    buttons = [Button.BLUE, Button.GREEN, Button.YELLOW, Button.RED];
    setState(State.IDLE);
  }

  void start() {
    sequence.clear();
    nextLevel();
  }

  void nextLevel() {
    sequence.add(nextRandomButton());
    playSequence(sequence);
  }

  void gameOver() {
    inactivateAll();
    setState(State.IDLE);
  }

  void playSequence(List<Button> sequence) {
    setState(State.PLAYING);
    inactivateAll();
    Button head = sequence.first;
    List<Button> tail = sequence.sublist(1, sequence.length);
    Completer completer = new Completer();
    new Future.delayed(defaultDuration, () {
      playButton(completer, head, tail);
    });
    completer.future.whenComplete(() {
      inactivateAll();
      listenForSequence(sequence);
    });
  }

  void playButton(Completer completer, Button head, List<Button> tail) {
    head.active = true;
    new Future.delayed(defaultDuration, () {
      head.active = false;
    }).then((_) {
      if (tail.isEmpty) {
        new Future.delayed(defaultDuration, () => completer.complete());
      } else {
        Button newHead = tail.first;
        List<Button> newTail = tail.sublist(1, tail.length);
        new Future.delayed(defaultDuration, () => playButton(completer, newHead, newTail));
      }
    });
  }

  void listenForSequence(List<Button> sequence) {
    setState(State.LISTENING);
    listeningSequence.clear();
    listeningSequence.addAll(sequence.reversed);
  }

  Button nextRandomButton() {
    return buttons[r.nextInt(4)];
  }

  void onKeyUp(dom.KeyboardEvent event) {
    if (isIdle() || isListening()) {
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
        default: // ignore all others
      }
      new Future.delayed(defaultDuration, () => inactivateAll());
    }
  }

  bool onClick(Button b) {
    if (isIdle() || isListening()) {
      b.active = true;
      if (isListening()) {
        Button last = listeningSequence.removeLast();
        if (last != b) {
          gameOver();
        } else if (listeningSequence.isEmpty) {
          new Future.delayed(defaultDuration, () => nextLevel());
        }
      }
    }
  }

  bool isIdle() => State.IDLE == state;

  bool isListening() => State.LISTENING == state;

  void inactivateAll() => buttons.forEach((b) {
    b.active = false;
  });

  void setState(State newState) {
    switch (newState) {
      case State.IDLE:
        if (state == State.LISTENING) {
          header = getLevel() + ": Ooops... Nochmal?";
        } else {
          header = "Start";
        }
        break;
      case State.PLAYING:
        header = getLevel() + ": Zuhören...";
        break;
      case State.LISTENING:
        header = getLevel() + ": Nachspielen!";
        break;
    }
    state = newState;
  }

  String getLevel() => "Level " + (sequence.length + 1).toString();

}

class Button {

  static final BLUE = new Button("blue");
  static final GREEN = new Button("green");
  static final YELLOW = new Button("yellow");
  static final RED = new Button("red");

  final String color;
  bool active;

  Button(this.color);

  String toString() => color;

}

class State {
  static const IDLE = const State._(0);
  static const PLAYING = const State._(1);
  static const LISTENING = const State._(2);

  static get values => [IDLE, PLAYING, LISTENING];

  final int value;

  const State._(this.value);
}

class SimonSaysModule extends Module {
  SimonSaysModule() {
    type(GameController);
  }
}

main() {
  ngBootstrap(module: new SimonSaysModule());
}