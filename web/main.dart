import 'package:angular/angular.dart';
import 'dart:math';
import 'dart:core';
import 'dart:async';
import 'dart:html';
import 'dart:web_audio';
import 'dart:math';

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
  final AudioContext audioCtx;

  State state;
  String header;
  bool showCheckMark;

  GameController(this.audioCtx) {
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
      Duration speed = calcSpeed(sequence.length);
      playSequence(speed, sequence);
    });
  }

  Duration calcSpeed(int sequenceLength) {
    // accelerate exponentially
    int ms = defaultDuration.inMilliseconds * pow(10, -(sequenceLength / 10));
    return new Duration(milliseconds: ms);
  }

  void gameOver() {
    inactivateAll();
    state = State.GAME_OVER;
  }

  void playSequence(Duration speed, List<Button> sequence) {
    state = State.PLAYING;
    inactivateAll();
    Button head = sequence.first;
    List<Button> tail = sequence.sublist(1, sequence.length);
    Completer completer = new Completer();
    new Future.delayed(speed, () {
      recursivelyPlayButtons(speed, completer, head, tail);
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

  void recursivelyPlayButtons(Duration speed, Completer completer, Button head, List<Button> tail) {
    head.play(audioCtx);
    new Future.delayed(speed, () {
      head.active = false;
    }).then((_) {
      if (tail.isEmpty) {
        new Future.delayed(speed, () => completer.complete());
      } else {
        Button newHead = tail.first;
        List<Button> newTail = tail.sublist(1, tail.length);
        new Future.delayed(speed, () => recursivelyPlayButtons(speed, completer, newHead, newTail));
      }
    });
  }

  void listenForSequence(List<Button> sequence) {
    state = State.LISTENING;
    listeningSequence.clear();
    listeningSequence.addAll(sequence.reversed);
  }

  Button nextRandomButton() => buttons[r.nextInt(4)];

  void onKeyUp(KeyboardEvent event) {
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

  bool onClick(Button button) {
    if (isInputEnabled()) {
      button.play(audioCtx);
      if (isListening()) {
        Button last = listeningSequence.removeLast();
        if (last != button) {
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

  static final BLUE = new Button("blue", "\u2190", "c.ogg");
  static final GREEN = new Button("green", "\u2191", "d.ogg");
  static final YELLOW = new Button("yellow", "\u2193", "e.ogg");
  static final RED = new Button("red", "\u2192", "f.ogg");

  final String color;
  final String keyBinding;
  final String audioUrl;

  bool active;
  AudioBuffer audioBuffer;

  Button(this.color, this.keyBinding, this.audioUrl);

  void play(AudioContext audioCtx) {
    active = true;
    AudioBufferSourceNode source = audioCtx.createBufferSource();
    source.buffer = audioBuffer;
    source.connectNode(audioCtx.destination, 0, 0);
    source.start(0);
  }

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
  SimonSaysModule(AudioContext audioCtx) {
    value(AudioContext, audioCtx);
    type(GameController);
  }
}

main() {
  AudioContext audioCtx = new AudioContext();
  [Button.BLUE, Button.GREEN, Button.YELLOW, Button.RED].forEach((button) {
    loadAudioBuffer(audioCtx, button);
  });
  ngBootstrap(module: new SimonSaysModule(audioCtx));
}

void loadAudioBuffer(AudioContext audioCtx, Button button) {
  var request = new HttpRequest();
  request.open("GET", button.audioUrl, async: true);
  request.responseType = "arraybuffer";
  request.onLoad.listen((e) {
    audioCtx.decodeAudioData(request.response).then((AudioBuffer buffer) => button.audioBuffer = buffer);
  });
  request.send();
}