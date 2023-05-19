import 'package:flutter/material.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/* 

To get the iOS app working -

1. Add the following lines to the ios/Runner/Podfile in the post_install do 
   section:

  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
         end
    end
  end

2. Add the following lines to the ios/Runner/Info.plist file:
	<key>NSMicrophoneUsageDescription</key>
	<string>This app accesses the microphone for speech to text</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>This app uses speech recognition for speech to text</string>

To get the Android app working -

1. Change the minSdkVersion to 21 in the android/app/build.gradle file

2. Add the following to android/app/src/main/AndroidManifest.xml under the
   manifest line:

   <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>   

*/

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key, required this.title});

  final String title;

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechToText speech = SpeechToText();

  String _currentLocaleId = '';

  String lastWords = '';
  String lastError = '';

  bool _hasSpeech = false;
  bool _listening = false;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSpeechState();
  }

  // This initializes SpeechToText. That only has to be done
  // once per application. Though calling it again is harmless,
  // it does nothing.
  Future<void> initSpeechState() async {
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        debugLogging: false,
      );
      if (hasSpeech) {
        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (exception) {
      setState(() {
        lastError = 'Speech initialization failed: ${exception.toString()}';
        _controller.text = lastError;
      });
    }
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = error.errorMsg;
      _controller.text = lastError;
    });
  }

  // This is called each time the users wants to start a new speech
  // recognition session
  void startListening() {
    lastWords = '';
    lastError = '';
    setState(() {
      _controller.text = '';
    });
    if (_hasSpeech) {
      try {
        // Note that `listenFor` is the maximum, not the minimun, on some
        // systems recognition will be stopped before this value is reached.
        // Similarly `pauseFor` is a maximum, not a minimum, and may be ignored
        // on some devices.
        speech.listen(
          onResult: resultListener,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: _currentLocaleId,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          onDevice: false,
        )
            .then((_) {
          setState(() {
            _listening = true;
          });
        });
      } catch (exception) {
        setState(() {
          lastError = 'Speech recognition failed: ${exception.toString()}';
          _controller.text = lastError;
        });
      }
    } else {
      setState(() {
        _controller.text = 'Speech recognition not available';
      });
    }
  }

  void stopListening() {
    speech.stop().then((_) {
      setState(() {
        _listening = false;
      });
    });
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
      _controller.text = lastWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextButton(
                  onPressed: () {
                    if (_listening) {
                      stopListening();
                    } else {
                      startListening();
                    }
                  },
                  child: Text(
                    _listening ? 'Stop Listening' : 'Start Listening',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
            ),
          )
        ],
      ),
    );
  }
}
