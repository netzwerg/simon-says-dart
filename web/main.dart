import 'package:angular/angular.dart';
import 'dart:math';
import 'dart:core';
import 'dart:async';
import 'dart:html';
import 'dart:web_audio';
import 'dart:math';
import 'audio/audio.dart';

@NgController(selector: '[gameCtrl]', publishAs: 'ctrl')
class GameController {

  static const int LEFT_ARROW = 37;
  static const int UP_ARROW = 38;
  static const int DOWN_ARROW = 40;
  static const int RIGHT_ARROW = 39;
  static const int SPACE = 32;
  static const int HUMAN_FRIENDLY_MIN_DURATION_MS = 70;

  final Random r = new Random();
  final Duration defaultDuration = new Duration(milliseconds: 500);
  final List<Button> buttons = [Button.BLUE, Button.GREEN, Button.YELLOW, Button.RED];
  final List<Button> sequence = [];
  final List<Button> listeningSequence = [];
  final AudioManager audio;

  State state;
  String header;
  bool showCheckMark;

  GameController(this.audio) {
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

  Button nextRandomButton() => buttons[r.nextInt(buttons.length)];

  Duration calcSpeed(int sequenceLength) {
    // accelerate gradually, but stop at max speed
    int ms = defaultDuration.inMilliseconds * pow(10, -(sequenceLength / 10));
    int humanFriendlyMs = max(ms, HUMAN_FRIENDLY_MIN_DURATION_MS);
    return new Duration(milliseconds: humanFriendlyMs);
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
    head.play(audio);
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
      button.play(audio);
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

  void gameOver() {
    inactivateAll();
    state = State.GAME_OVER;
    audio.play(AudioManager.URL_PIANO_F_6);
  }

}

class Button {

  static final BLUE = new Button("blue", "\u2190", AudioManager.URL_PIANO_C);
  static final GREEN = new Button("green", "\u2191", AudioManager.URL_PIANO_D);
  static final YELLOW = new Button("yellow", "\u2193", AudioManager.URL_PIANO_E);
  static final RED = new Button("red", "\u2192", AudioManager.URL_PIANO_F);

  final String color;
  final String keyBinding;
  final String audioUrl;

  bool active;

  Button(this.color, this.keyBinding, this.audioUrl);

  void play(AudioManager audio) {
    active = true;
    audio.play(audioUrl);
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
  SimonSaysModule(AudioManager audio) {
    value(AudioManager, audio);
    type(GameController);
  }
}

const String AUDIO_URL_PREFIX = "audio";

main() {
  AudioManager audio = new AudioManager(AUDIO_URL_PREFIX);
  audio.loadAudioBuffers();
  ngBootstrap(module: new SimonSaysModule(audio));
}