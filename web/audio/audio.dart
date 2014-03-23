import 'dart:web_audio';
import 'dart:html';
import 'dart:collection';

class AudioManager {

  static const String URL_PIANO_C = "audio/c.ogg";
  static const String URL_PIANO_D = "audio/d.ogg";
  static const String URL_PIANO_E = "audio/e.ogg";
  static const String URL_PIANO_F = "audio/f.ogg";
  static const String URL_PIANO_F_6 = "audio/f6.ogg";

  final List<String> allUrls = [URL_PIANO_C, URL_PIANO_D, URL_PIANO_E, URL_PIANO_F, URL_PIANO_F_6];
  final Map<String, AudioBuffer> buffersByUrl = new HashMap<String, AudioBuffer>();

  final AudioContext audioCtx = new AudioContext();

  void loadAudioBuffers() {
    allUrls.forEach((url) {
      var request = new HttpRequest();
      request.open("GET", url, async: true);
      request.responseType = "arraybuffer";
      request.onLoad.listen((e) {
        audioCtx.decodeAudioData(request.response).then((AudioBuffer buffer) => buffersByUrl.putIfAbsent(url, () => buffer));
      });
      request.send();
    });
  }

  void play(String url) {
    AudioBufferSourceNode source = audioCtx.createBufferSource();
    source.buffer = buffersByUrl[url];
    source.connectNode(audioCtx.destination, 0, 0);
    source.start(0);
  }

}