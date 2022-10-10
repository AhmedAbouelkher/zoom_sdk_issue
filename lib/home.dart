import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_sdk/zoom_options.dart';
import 'package:flutter_zoom_sdk/zoom_view.dart';

//https://github.com/evilrat/flutter_zoom_sdk

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _idController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    _idController = TextEditingController();
    _passwordController = TextEditingController();
    if (kDebugMode) {
      _idController.text = "76510999443";
      _passwordController.text = "730JCx";
    }

    super.initState();
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(onPressed: () {
        startMeeting(context);
      }),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Meeting ID',
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                joinMeeting(
                  context,
                  meetingIdController: _idController,
                  passwordController: _passwordController,
                );
              },
              child: const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}

void joinMeeting(
  BuildContext context, {
  required TextEditingController meetingIdController,
  required TextEditingController passwordController,
}) {
  bool _isMeetingEnded(String status) {
    var result = false;

    if (Platform.isAndroid)
      result = status == "MEETING_STATUS_DISCONNECTING" || status == "MEETING_STATUS_FAILED";
    else
      result = status == "MEETING_STATUS_IDLE";

    return result;
  }

  if (meetingIdController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Enter a valid meeting id to continue."),
    ));
    return;
  }

  ZoomOptions zoomOptions = ZoomOptions(
    domain: "zoom.us",
    appKey: "PjkCVh3mjJHy9h7DAsAmAjbuvzXJja1l20yf", //API KEY FROM ZOOM - Sdk API Key
    appSecret: "5HpBp74o1wGdJTZxNJhUYwm5lmdCoMUWBp4x", //API SECRET FROM ZOOM - Sdk API Secret
    language: "ar-EG",
    disableInvite: true,
    disableRecord: true,
  );
  var meetingOptions = ZoomMeetingOptions(
    userId: 'ahmed', //pass username for join meeting only --- Any name eg:- EVILRATT.
    meetingId: meetingIdController.text.trim(), //pass meeting id for join meeting only
    meetingPassword: passwordController.text.trim(), //pass meeting password for join meeting only
    disableDialIn: "true",
    disableDrive: "true",
    disableInvite: "true",
    disableShare: "true",
    disableTitlebar: "false",
    viewOptions: "true",
    noAudio: "true",
    noDisconnectAudio: "false",
  );

  var zoom = ZoomView();
  late Timer timer;
  zoom.initZoom(zoomOptions).then((results) {
    if (results[0] == 0) {
      zoom.onMeetingStatus().listen((status) {
        print("[Meeting Status Stream] : " + status[0] + " - " + status[1]);
        if (_isMeetingEnded(status[0])) {
          print("[Meeting Status] :- Ended");
          timer.cancel();
        }
      });
      print("listen on event channel");
      zoom.joinMeeting(meetingOptions).then((joinMeetingResult) {
        timer = Timer.periodic(new Duration(seconds: 2), (timer) {
          zoom.meetingStatus(meetingOptions.meetingId!).then((status) {
            print("[Meeting Status Polling] : " + status[0] + " - " + status[1]);
          });
        });
      });
    }
  }).catchError((error) {
    print("[Error Generated] : " + error);
  });
}

void startMeeting(BuildContext context) {
  bool _isMeetingEnded(String status) {
    var result = false;

    if (Platform.isAndroid)
      result = status == "MEETING_STATUS_DISCONNECTING" || status == "MEETING_STATUS_FAILED";
    else
      result = status == "MEETING_STATUS_IDLE";

    return result;
  }

  ZoomOptions zoomOptions = ZoomOptions(
    domain: "zoom.us",
    appKey: "PjkCVh3mjJHy9h7DAsAmAjbuvzXJja1l20yf", //API KEY FROM ZOOM - Sdk API Key
    appSecret: "5HpBp74o1wGdJTZxNJhUYwm5lmdCoMUWBp4x", //API SECRET FROM ZOOM - Sdk API Secret
  );
  var meetingOptions = ZoomMeetingOptions(
    userId: 'am303737@gmail.com', //pass host email for zoom
    userPassword: 'password', //pass host password for zoom
    disableDialIn: "false",
    disableDrive: "false",
    disableInvite: "false",
    disableShare: "false",
    disableTitlebar: "false",
    viewOptions: "false",
    noAudio: "false",
    noDisconnectAudio: "false",
  );

  var zoom = ZoomView();
  zoom.initZoom(zoomOptions).then((results) {
    if (results[0] == 0) {
      zoom.onMeetingStatus().listen((status) {
        print("[Meeting Status Stream] : " + status[0] + " - " + status[1]);
        if (_isMeetingEnded(status[0])) {
          print("[Meeting Status] :- Ended");
        }
        if (status[0] == "MEETING_STATUS_INMEETING") {
          zoom.meetinDetails().then((meetingDetailsResult) {
            print("[MeetingDetailsResult] :- " + meetingDetailsResult.toString());
          });
        }
      });
      zoom.startMeeting(meetingOptions).then((loginResult) {
        print("[LoginResult] :- " + loginResult[0] + " - " + loginResult[1]);
        if (loginResult[0] == "SDK ERROR") {
          //SDK INIT FAILED
          print((loginResult[1]).toString());
        } else if (loginResult[0] == "LOGIN ERROR") {
          //LOGIN FAILED - WITH ERROR CODES
          if (loginResult[1] == ZoomError.ZOOM_AUTH_ERROR_WRONG_ACCOUNTLOCKED) {
            print("Multiple Failed Login Attempts");
          }
          print((loginResult[1]).toString());
        } else {
          //LOGIN SUCCESS & MEETING STARTED - WITH SUCCESS CODE 200
          print((loginResult[0]).toString());
        }
      });
    }
  }).catchError((error) {
    print("[Error Generated] : " + error);
  });
}
