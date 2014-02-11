import 'package:angular/angular.dart';
import 'dart:math';
import 'dart:async';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(override: '*')
import 'dart:mirrors';

@NgController(selector: '[gameCtrl]', publishAs: 'ctrl')
class GameController {

  final Random r = new Random();

  List<Button> buttons;
  List<Button> sequence;

  GameController() {
    buttons = [new Button("blue"), new Button("green"), new Button("yellow"), new Button("red")];
  }

  void start() {
    nextRandomButton().active = true;
    Duration duration = new Duration(milliseconds: 500);
    Timer timer = new Timer(duration, () => inactivateAll());
  }

  Button nextRandomButton() {
    return buttons[r.nextInt(4)];
  }

  bool click(Button b) => b.active = true;

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

class SimonSaysModule extends Module {
  SimonSaysModule() {
    type(GameController);
  }
}

main() {
  ngBootstrap(module: new SimonSaysModule());
}