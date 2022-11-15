import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/settingNotifier.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:image_picker/image_picker.dart';

class GrabbingWidget extends StatelessWidget {
  final Function() changeState;
  var email = "";

  GrabbingWidget(this.changeState, {super.key});

  @override
  Widget build(BuildContext context) {
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    email = auth.user!.email!;
    return GestureDetector(
      onTap: () {
        changeState();
      },
      child: Container(
        alignment: Alignment.centerLeft,
        color: Colors.grey[500],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                "Welcome back, $email", //auth.email
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: auth.isPosEnable
                  ? const Icon(Icons.keyboard_arrow_down)
                  : const Icon(Icons.keyboard_arrow_up),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginSheet extends StatefulWidget {
  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  var snappingController = SnappingSheetController();
  var avatarUrl =
      "https://firebasestorage.googleapis.com/v0/b/hellome-f88ec.appspot.com/o/users%2Flogo.png?alt=media&token=7e573aa5-8763-4fe1-a08c-76ac8acc9993";
  bool loading = true;

  @override
  void initState() {
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    super.initState();
    loadAvatar(auth);
  }

  void loadAvatar(SettingNotifier auth) async {
    var avatar = await auth.getAvatar();
    setState(() {
      loading = false;
      avatarUrl = avatar;
    });
  }

  uploadAavatar() async {
    setState(() {
      loading = true;
    });
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    ImagePicker().pickImage(source: ImageSource.gallery).then((value) async {
      if (value == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No image selected')));
        return;
      }
      var image = io.File(value.path);
      Reference ref = FirebaseStorage.instance
          .ref("users/${auth.user!.email}")
          .child("avatar.jpg");
      UploadTask task = ref.putFile(io.File(image.path));
      task.then((value) async {
        var url = await value.ref.getDownloadURL();
        setState(() {
          loading = false;
          avatarUrl = url;
        });
        auth.changeAvatar(url);
      });
    });
  }

  var enabledPos = [
    const SnappingPosition.factor(
      grabbingContentOffset: GrabbingContentOffset.bottom,
      positionFactor: 0.25,
      snappingCurve: Curves.easeOutCirc,
      snappingDuration: Duration(milliseconds: 500),
    ),
    const SnappingPosition.factor(
      grabbingContentOffset: GrabbingContentOffset.bottom,
      positionFactor: 0.8,
      snappingCurve: Curves.easeOutCirc,
      snappingDuration: Duration(milliseconds: 500),
    ),
  ];

  var disabledPos = [
    const SnappingPosition.factor(
      grabbingContentOffset: GrabbingContentOffset.bottom,
      positionFactor: 0.09,
      snappingCurve: Curves.easeOutCirc,
      snappingDuration: Duration(milliseconds: 500),
    ),
  ];

  void changeState() {
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    setState(() {
      auth.isPosEnable = !auth.isPosEnable;
      snappingController
          .snapToPosition(auth.isPosEnable ? enabledPos[0] : disabledPos[0]);
    });
  }

  @override
  Widget build(BuildContext context) {
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    return SnappingSheet(
      controller: snappingController,
      lockOverflowDrag: true,
      grabbingHeight: 55,
      grabbing: GrabbingWidget(changeState),
      sheetAbove: auth.isPosEnable
          ? SnappingSheetContent(
              draggable: false,
              child: const AboveSheet(),
            )
          : null,
      initialSnappingPosition: const SnappingPosition.factor(
        grabbingContentOffset: GrabbingContentOffset.bottom,
        positionFactor: 0.12,
        snappingCurve: Curves.easeOutCirc,
        snappingDuration: Duration(milliseconds: 500),
      ),
      snappingPositions: auth.isPosEnable ? enabledPos : disabledPos,
      sheetBelow: snappingContent(),
      child: null,
    );
  }

  SnappingSheetContent snappingContent() {
    var auth = Provider.of<SettingNotifier>(context, listen: false);
    return SnappingSheetContent(
      draggable: true,
      child: Container(
        color: Colors.white,
        child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView(
                children: [
                  Row(
                    children: [
                      if (loading)
                        const CircularProgressIndicator()
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                            avatarUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                auth.user!.email!,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: SizedBox(
                                width: 140,
                                height: 30,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                  ),
                                  onPressed: () => uploadAavatar(),
                                  child: const Text(
                                    "Change avatar",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
      ),
    );
  }
}

class AboveSheet extends StatelessWidget {
  const AboveSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 2.0,
          sigmaY: 2.0,
        ),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}
