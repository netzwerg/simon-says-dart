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

  final Random r = new Random();
  final Duration defaultDuration = new Duration(milliseconds: 500);

  List<Button> buttons = [];
  final List<Button> sequence = [];
  final List<Button> listeningSequence = [];
  State state;

  GameController() {
    buttons = [new Button("blue"), new Button("green"), new Button("yellow"), new Button("red")];
    state = State.IDLE;
  }

  void start() {
    sequence.clear();
    nextLevel();
  }

  void nextLevel() {
    dom.window.alert('Yay! Level ' + (sequence.length + 1).toString());
    sequence.add(nextRandomButton());
    sequence.forEach((c) => print("Sequence " + c.toString()));
    playSequence(sequence);
  }

  void gameOver() {
    dom.window.alert('Game Over');
    state = State.IDLE;
  }

  void playSequence(List<Button> sequence) {
    state = State.PLAYING;
    inactivateAll();
    Button head = sequence.first;
    List<Button> tail = sequence.sublist(1, sequence.length);
    Completer completer = new Completer();
    playButton(completer, head, tail);
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
    state = State.LISTENING;
    listeningSequence.clear();
    listeningSequence.addAll(sequence.reversed);
  }

  Button nextRandomButton() {
    return buttons[r.nextInt(4)];
  }

  bool click(Button b) {
    if (isIdle() || isListening()) {
      b.active = true;
      if (isListening()) {
        Button last = listeningSequence.removeLast();
        if (last != b) {
          gameOver();
        } else if (listeningSequence.isEmpty) {
          nextLevel();
        }
      }
    }
  }

  bool isIdle() => State.IDLE == state;

  bool isListening() => State.LISTENING == state;

  void inactivateAll() => buttons.forEach((b) {
    b.active = false;
  });

}

class Button {

  String color;
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