import 'package:angular/angular.dart';
import 'dart:html';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(override: '*')
import 'dart:mirrors';

@NgController(selector: '[buttons]', publishAs: 'ctrl')
class ButtonController {

  List<Button> buttons;

  ButtonController() {
    buttons = [new Button("blue"), new Button("green"), new Button("yellow"), new Button("red"), ];
  }

  void click(Button b) {
    b.setActive(true);
  }

  void inactivateAll() {
    buttons.forEach((b) {b.setActive(false);});
  }

}

class Button {

  String color;
  bool active;

  Button(this.color);

  void setActive(bool active) {
    this.active = active;
  }
}

class SimonSaysModule extends Module {
  SimonSaysModule() {
    type(ButtonController);
  }
}

main() {
  ngBootstrap(module: new SimonSaysModule());
}