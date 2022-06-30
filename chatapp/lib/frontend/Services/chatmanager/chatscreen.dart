// ignore_for_file: prefer_const_constructors, prefer_final_fields, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps, prefer_const_declarations, prefer_collection_literals, unnecessary_this

import 'package:chatapp/backend/firebase/online_database_management/clouddatamanager.dart';
import 'package:chatapp/backend/sqlitemanagement/localdatabasemanagement.dart';
import 'package:chatapp/frontend/model/previousmessages.dart';
import 'package:chatapp/frontend/preview/imagepreviewscreen.dart';
import 'package:chatapp/global_uses/constants.dart';
import 'package:chatapp/global_uses/enums.dart';
import 'package:chatapp/global_uses/nativecalling.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chatapp/global_uses/showtoastmessages.dart';
import 'package:flutter/material.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:animations/animations.dart';
import 'package:circle_list/circle_list.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  ChatScreen({required this.userName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoading = false;
  late double _currAudioPlayingTime = 0;
  IconData _iconData = Icons.play_arrow_rounded;
  double _audioPlayingSpeed = 1.0;
  bool _showEmojiPicker = false;
  String _totalDuration = '0:00';
  String _loadingTime = '0:00';
  final Dio dio = Dio();
  String _hintText = "Type Here...";
  int _lastAudioPlayingIndex = 0;
  String _connectionEmail = "";
  final Record _record = Record();
  final AudioPlayer _justAudioPlayer = AudioPlayer();
  late Directory _audioDirectory;
  double _chatBoxHeight = 0.0;
  final NativeCallback _nativeCallback = NativeCallback();
  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 0.0,
  );

  final FirestoreFieldConstants _firestoreFieldConstants =
      FirestoreFieldConstants();

  @override
  void initState() {
    _fToast.init(context);
    _takePermissionForStorage();
    _getConnectionEmail();
    _loadPreviousStoredMessages();
    super.initState();
  }

  @override
  void dispose() {
    _justAudioPlayer.dispose();
    super.dispose();
  }

  bool _isoLoading = false;
  bool lastDirection = false;
  final FToast _fToast = FToast();
  bool textpresent = false;

  final String _messageAndTimeSeparator =
      "${DateTime.now().hour}:${DateTime.now().minute}";

  List<Map<String, String>> _allConversationMessages = [];
  List<bool> _conversationMessageHolder = [];
  List<ChatMessageTypes> _chatMessageCategoryHolder = [];
  final LocalDatabase _localDatabase = LocalDatabase();
  final CloudStorage _cloudStoreDataManagement = CloudStorage();

  TextEditingController chatController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    _chatBoxHeight = MediaQuery.of(context).size.height - 150;
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (_showEmojiPicker) {
            if (mounted) {
              setState(() {
                _showEmojiPicker = false;
                _chatBoxHeight += 300;
              });
            }
            return false;
          }
          return true;
        },
        child: Scaffold(
          //bottomSheet: _bottomSheet(),
          appBar: AppBar(
            backgroundColor: Color.fromRGBO(25, 39, 52, 1),
            elevation: 0.0,
            title: Text(widget.userName),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: Row(
              children: <Widget>[
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: OpenContainer(
                    closedColor: const Color.fromRGBO(25, 39, 52, 1),
                    middleColor: const Color.fromRGBO(25, 39, 52, 1),
                    openColor: const Color.fromRGBO(25, 39, 52, 1),
                    closedShape: CircleBorder(),
                    closedElevation: 0.0,
                    transitionType: ContainerTransitionType.fadeThrough,
                    transitionDuration: Duration(milliseconds: 500),
                    openBuilder: (_, __) {
                      return Center();
                    },
                    closedBuilder: (_, __) {
                      return CircleAvatar(
                        radius: 23.0,
                        backgroundColor: const Color.fromRGBO(25, 39, 52, 1),
                        backgroundImage: ExactAssetImage(
                          "assets/images/google.png",
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.call,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          backgroundColor: Color.fromRGBO(34, 48, 60, 1),
          body: LoadingOverlay(
            isLoading: _isLoading,
            color: Colors.black54,
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                      padding: EdgeInsets.all(2.5),
                      width: double.maxFinite,
                      height: _showEmojiPicker
                          ? _chatBoxHeight - 298
                          : _chatBoxHeight,
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: _allConversationMessages.length,
                        itemBuilder: (itemBuilderContext, index) {
                          if (_chatMessageCategoryHolder[index] ==
                              ChatMessageTypes.Text)
                            return _textConversationManagement(
                                itemBuilderContext, index);
                          else if (_chatMessageCategoryHolder[index] ==
                              ChatMessageTypes.Image)
                            return _mediaConversationManagement(
                                itemBuilderContext, index);
                          else if (_chatMessageCategoryHolder[index] ==
                              ChatMessageTypes.Video)
                            return _mediaConversationManagement(
                                itemBuilderContext, index);
                          else if (_chatMessageCategoryHolder[index] ==
                              ChatMessageTypes.Document)
                            return _documentConversationManagement(
                                itemBuilderContext, index);
                          else if (_chatMessageCategoryHolder[index] ==
                              ChatMessageTypes.Location)
                            return _locationConversationManagement(
                                itemBuilderContext, index);
                          else if (_chatMessageCategoryHolder[index] ==
                              ChatMessageTypes.Audio)
                            return _audioConversationManagement(
                                itemBuilderContext, index);
                          return Center();
                        },
                      )),
                  Container(
                    width: double.maxFinite,
                    height: 60,
                    child: _bottomSheet(),
                  ),
                  _showEmojiPicker
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 300.0,
                          child: EmojiPicker(
                            onEmojiSelected: (category, emoji) {
                              if (mounted) {
                                setState(() {
                                  chatController.text += emoji.emoji;
                                  chatController.text.isEmpty
                                      ? textpresent = false
                                      : textpresent = true;
                                });
                              }
                            },
                            onBackspacePressed: () {
                              // Backspace-Button tapped logic
                              // Remove this line to also remove the button in the UI
                            },
                            config: Config(
                                columns: 7,
                                emojiSizeMax: 32.0,
                                verticalSpacing: 0,
                                horizontalSpacing: 0,
                                initCategory: Category.RECENT,
                                bgColor: Color(0xFFF2F2F2),
                                indicatorColor: Colors.blue,
                                iconColor: Colors.grey,
                                iconColorSelected: Colors.blue,
                                progressIndicatorColor: Colors.blue,
                                showRecentsTab: true,
                                recentsLimit: 28,
                                noRecents: Text("No Recents"),
                                buttonMode: ButtonMode.MATERIAL),
                          ),
                        )
                      : SizedBox()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _loadPreviousStoredMessages() async {
    double _positionToScroll = 100.0;

    try {
      // if (mounted) {
      //   setState(() {
      //     this._isLoading = true;
      //   });
      // }

      List<PreviousMessageStructure> _storedPreviousMessages =
          await _localDatabase.getAllPreviousMessages(widget.userName);

      for (int i = 0; i < _storedPreviousMessages.length; i++) {
        final PreviousMessageStructure _previousMessage =
            _storedPreviousMessages[i];

        if (mounted) {
          setState(() {
            _allConversationMessages.add({
              _previousMessage.actualMessage: _previousMessage.messageTime,
            });
            _chatMessageCategoryHolder.add(_previousMessage.messageType);
            _conversationMessageHolder.add(_previousMessage.messageHolder);

            _positionToScroll += _amountToScroll(_previousMessage.messageType,
                actualMessageKey: _previousMessage.actualMessage);
          });
        }
      }
    } catch (e) {
      print("Previous Message Fetching Error in ChatScreen: ${e.toString()}");
    } finally {
      // if (mounted) {
      //   setState(() {
      //     this._isLoading = false;
      //   });
      // }

      if (mounted) {
        setState(() {
          print("Position to Scroll: $_positionToScroll");
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent + _positionToScroll,
          );
        });
      }
      await _fetchIncomingMessages();
    }
  }

  Future<void> _checkingForIncomingMessages(Map<String, dynamic>? docs) async {
    final Map<String, dynamic> _connectionsList =
        docs![_firestoreFieldConstants.connections];

    List<dynamic>? getIncomingMessages = _connectionsList[_connectionEmail];

    if (getIncomingMessages != null) {
      await _cloudStoreDataManagement
          .removeOldMessages(connectionEmail: _connectionEmail)
          .whenComplete(() {
        getIncomingMessages.forEach((everyMessage) {
          if (everyMessage.keys.first.toString() ==
              ChatMessageTypes.Text.toString()) {
            Future.microtask(() {
              _manageIncomingTextMessages(everyMessage.values.first);
            });
          } else if (everyMessage.keys.first.toString() ==
              ChatMessageTypes.Audio.toString()) {
            Future.microtask(() {
              _manageIncomingMediaMessages(
                  everyMessage.values.first, ChatMessageTypes.Audio);
            });
          } else if (everyMessage.keys.first.toString() ==
              ChatMessageTypes.Image.toString()) {
            Future.microtask(() {
              _manageIncomingMediaMessages(
                  everyMessage.values.first, ChatMessageTypes.Image);
            });
          } else if (everyMessage.keys.first.toString() ==
              ChatMessageTypes.Video.toString()) {
            Future.microtask(() {
              _manageIncomingMediaMessages(
                  everyMessage.values.first, ChatMessageTypes.Video);
            });
          } else if (everyMessage.keys.first.toString() ==
              ChatMessageTypes.Location.toString()) {
            Future.microtask(() {
              _manageIncomingLocationMessages(everyMessage.values.first);
            });
          } else if (everyMessage.keys.first.toString() ==
              ChatMessageTypes.Document.toString()) {
            Future.microtask(() {
              _manageIncomingMediaMessages(
                  everyMessage.values.first, ChatMessageTypes.Document);
            });
          }
        });
      });
    }

    print('Get Incoming Messages: $getIncomingMessages');
  }

  _manageIncomingLocationMessages(var locationMessage) async {
    await _localDatabase.insertMessageInUserTable(
        userName: widget.userName,
        actualMessage: locationMessage.keys.first.toString(),
        chatMessageTypes: ChatMessageTypes.Location,
        messageHolderType: MessageHolderType.ConnectedUsers,
        messageDateLocal: DateTime.now().toString().split(" ")[0],
        messageTimeLocal: locationMessage.values.first.toString());

    if (mounted) {
      setState(() {
        this._allConversationMessages.add({
          locationMessage.keys.first.toString():
              locationMessage.values.first.toString(),
        });
        this._chatMessageCategoryHolder.add(ChatMessageTypes.Location);
        this._conversationMessageHolder.add(true);
      });
    }

    if (mounted) {
      setState(() {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent +
              _amountToScroll(ChatMessageTypes.Location),
        );
      });
    }
  }

  _manageIncomingMediaMessages(
      var mediaMessage, ChatMessageTypes chatMessageTypes) async {
    String refName = "";
    String extension = "";
    late String thumbnailFileRemotePath;

    String videoThumbnailLocalPath = "";

    String actualFileRemotePath = chatMessageTypes == ChatMessageTypes.Video ||
            chatMessageTypes == ChatMessageTypes.Document
        ? mediaMessage.keys.first.toString().split("+")[0]
        : mediaMessage.keys.first.toString();

    if (chatMessageTypes == ChatMessageTypes.Image) {
      refName = "/Images/";
      extension = '.png';
    } else if (chatMessageTypes == ChatMessageTypes.Video) {
      refName = "/Videos/";
      extension = '.mp4';
      thumbnailFileRemotePath =
          mediaMessage.keys.first.toString().split("+")[1];
    } else if (chatMessageTypes == ChatMessageTypes.Document) {
      refName = "/Documents/";
      extension = mediaMessage.keys.first.toString().split("+")[1];
    } else if (chatMessageTypes == ChatMessageTypes.Audio) {
      refName = "/Audio/";
      extension = '.mp3';
    }

    if (mounted) {
      setState(() {
        this._isLoading = true;
      });
    }

    final Directory? directory = await getExternalStorageDirectory();
    print('Directory Path: ${directory!.path}');

    final storageDirectory = await Directory(directory.path + refName)
        .create(); // Create New Folder about the desire location

    final String mediaFileLocalPath =
        "${storageDirectory.path}${DateTime.now().toString().split(" ").join("")}$extension";

    if (chatMessageTypes == ChatMessageTypes.Video) {
      final storageDirectory = await Directory(directory.path + "/.Thumbnails/")
          .create(); // Create New Folder about the desire location

      videoThumbnailLocalPath =
          "${storageDirectory.path}${DateTime.now().toString().split(" ").join("")}.png";
    }

    try {
      print("Media Saved Path: $mediaFileLocalPath");

      await dio
          .download(actualFileRemotePath, mediaFileLocalPath)
          .whenComplete(() async {
        if (chatMessageTypes == ChatMessageTypes.Video) {
          await dio
              .download(thumbnailFileRemotePath, videoThumbnailLocalPath)
              .whenComplete(() async {
            await _storeAndShowIncomingMessageData(
                mediaFileLocalPath:
                    "$videoThumbnailLocalPath+$mediaFileLocalPath",
                chatMessageTypes: chatMessageTypes,
                mediaMessage: mediaMessage);
          });
        } else {
          await _storeAndShowIncomingMessageData(
              mediaFileLocalPath: mediaFileLocalPath,
              chatMessageTypes: chatMessageTypes,
              mediaMessage: mediaMessage);
        }
      });
    } catch (e) {
      print("Error in Media Downloading: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent +
                _amountToScroll(chatMessageTypes,
                    actualMessageKey: mediaFileLocalPath),
          );
        });
      }
    }
  }

  Future<void> _storeAndShowIncomingMessageData(
      {required String mediaFileLocalPath,
      required ChatMessageTypes chatMessageTypes,
      required var mediaMessage}) async {
    try {
      await _localDatabase.insertMessageInUserTable(
          userName: widget.userName,
          actualMessage: mediaFileLocalPath,
          chatMessageTypes: chatMessageTypes,
          messageHolderType: MessageHolderType.ConnectedUsers,
          messageDateLocal: DateTime.now().toString().split(" ")[0],
          messageTimeLocal: mediaMessage.values.first.toString());

      if (mounted) {
        setState(() {
          _allConversationMessages.add({
            mediaFileLocalPath: mediaMessage.values.first.toString(),
          });
          _chatMessageCategoryHolder.add(chatMessageTypes);
          _conversationMessageHolder.add(true);
        });
      }
    } catch (e) {
      print("Error in Store And Show Message: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  _manageIncomingTextMessages(var textMessage) async {
    await _localDatabase.insertMessageInUserTable(
        userName: widget.userName,
        actualMessage: textMessage.keys.first.toString(),
        chatMessageTypes: ChatMessageTypes.Text,
        messageHolderType: MessageHolderType.ConnectedUsers,
        messageDateLocal: DateTime.now().toString().split(" ")[0],
        messageTimeLocal: textMessage.values.first.toString());

    if (mounted) {
      setState(() {
        _allConversationMessages.add({
          textMessage.keys.first.toString():
              textMessage.values.first.toString(),
        });
        _chatMessageCategoryHolder.add(ChatMessageTypes.Text);
        _conversationMessageHolder.add(true);
      });
    }

    if (mounted) {
      setState(() {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent +
              _amountToScroll(ChatMessageTypes.Text) +
              30.0,
        );
      });
    }
  }

  _getConnectionEmail() async {
    final String? getUserEmail =
        await _localDatabase.getParticularFieldDataFromImportantTable(
            userName: widget.userName,
            getField: GetFieldForImportantDataLocalDatabase.UserEmail);

    if (mounted) {
      setState(() {
        _connectionEmail = getUserEmail.toString();
      });
    }
  }

  Future<void> _fetchIncomingMessages() async {
    final realTimeSnapshot =
        await _cloudStoreDataManagement.fetchRealTimeMessages();

    realTimeSnapshot!.listen((documentSnapShot) async {
      await _checkingForIncomingMessages(documentSnapShot.data());
    });
  }

  Widget _audioConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onLongPress: () async {},
          child: Container(
            margin: _conversationMessageHolder[index]
                ? EdgeInsets.only(
                    right: MediaQuery.of(context).size.width / 3,
                    left: 5.0,
                    top: 5.0,
                  )
                : EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 3,
                    right: 5.0,
                    top: 5.0,
                  ),
            alignment: _conversationMessageHolder[index]
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              height: 70.0,
              width: 250.0,
              decoration: BoxDecoration(
                color: _conversationMessageHolder[index]
                    ? Color.fromRGBO(60, 80, 100, 1)
                    : Color.fromRGBO(102, 102, 255, 1),
                borderRadius: _conversationMessageHolder[index]
                    ? BorderRadius.only(
                        topRight: Radius.circular(40.0),
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(40.0),
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0),
                      ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20.0,
                  ),
                  GestureDetector(
                    onLongPress: () => _chatMicrophoneOnLongPressAction(),
                    onTap: () => chatMicrophoneOnTapAction(index),
                    child: Icon(
                      index == _lastAudioPlayingIndex
                          ? _iconData
                          : Icons.play_arrow_rounded,
                      color: Color.fromRGBO(10, 255, 30, 1),
                      size: 35.0,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              top: 26.0,
                            ),
                            child: LinearPercentIndicator(
                              percent: _justAudioPlayer.duration == null
                                  ? 0.0
                                  : _lastAudioPlayingIndex == index
                                      ? _currAudioPlayingTime /
                                                  _justAudioPlayer
                                                      .duration!.inMicroseconds
                                                      .ceilToDouble() <=
                                              1.0
                                          ? _currAudioPlayingTime /
                                              _justAudioPlayer
                                                  .duration!.inMicroseconds
                                                  .ceilToDouble()
                                          : 0.0
                                      : 0,
                              backgroundColor: Colors.black26,
                              progressColor: _conversationMessageHolder[index]
                                  ? Colors.lightBlue
                                  : Colors.amber,
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10.0, right: 7.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _lastAudioPlayingIndex == index
                                          ? _loadingTime
                                          : '0:00',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _lastAudioPlayingIndex == index
                                          ? _totalDuration
                                          : '',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: GestureDetector(
                      child: _lastAudioPlayingIndex != index
                          ? CircleAvatar(
                              radius: 23.0,
                              backgroundColor: _conversationMessageHolder[index]
                                  ? Color.fromRGBO(60, 80, 100, 1)
                                  : Color.fromRGBO(102, 102, 255, 1),
                              backgroundImage: ExactAssetImage(
                                "assets/images/google.png",
                              ),
                            )
                          : Text(
                              '${_audioPlayingSpeed.toString().contains('.0') ? _audioPlayingSpeed.toString().split('.')[0] : _audioPlayingSpeed}x',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18.0),
                            ),
                      onTap: () {
                        print('Audio Play Speed Tapped');
                        if (mounted) {
                          setState(() {
                            if (_audioPlayingSpeed != 3.0)
                              _audioPlayingSpeed += 0.5;
                            else
                              _audioPlayingSpeed = 1.0;

                            _justAudioPlayer.setSpeed(_audioPlayingSpeed);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _conversationMessageTime(
            _allConversationMessages[index].values.first, index),
      ],
    );
  }

  void _chatMicrophoneOnLongPressAction() async {
    if (_justAudioPlayer.playing) {
      await _justAudioPlayer.stop();

      if (mounted) {
        setState(() {
          print('Audio Play Completed');
          _justAudioPlayer.stop();
          if (mounted) {
            setState(() {
              _loadingTime = '0:00';
              _iconData = Icons.play_arrow_rounded;
              _lastAudioPlayingIndex = -1;
            });
          }
        });
      }
    }
  }

  Widget _bottomSheet() {
    return BottomSheet(
      backgroundColor: Color.fromRGBO(25, 39, 52, 1),
      builder: (BuildContext context) {
        return Container(
          width: double.maxFinite,
          height: 60,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 16, 38, 59),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                    }
                  },
                  child: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                InkWell(
                  onTap: () {
                    chatOptions();
                  },
                  child: Icon(
                    Icons.link_sharp,
                    color: Colors.blue[400],
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 60,
                    child: TextField(
                      onChanged: (text) {
                        bool _isEmpty = false;
                        text.isEmpty ? _isEmpty = true : _isEmpty = false;

                        if (mounted) {
                          setState(() {
                            textpresent = !_isEmpty;
                          });
                        }
                      },
                      controller: chatController,
                      maxLines: null,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _hintText,
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.lightBlue, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                GestureDetector(
                  onTap: () {
                    textpresent ? _sendText() : _voiceTake();
                  },
                  child: Icon(
                    textpresent ? Icons.send : Icons.mic,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onClosing: () {},
    );
  }

  void _voiceTake() async {
    if (!await Permission.microphone.status.isGranted) {
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted)
        showToast("Microphone Permission Required To Record Voice", _fToast);
    } else {
      if (await _record.isRecording()) {
        if (mounted) {
          setState(() {
            _hintText = 'Type Here...';
          });
        }
        final String? recordedFilePath = await _record.stop();

        _voiceAndAudioSend(recordedFilePath.toString());
      } else {
        if (mounted) {
          setState(() {
            _hintText = 'Recording....';
          });
        }

        await _record
            .start(
              path: '${_audioDirectory.path}${DateTime.now()}.aac',
            )
            .then((value) => print("Recording"));
      }
    }
  }

  void _sendText() async {
    if (textpresent) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final String _messageTime =
          "${DateTime.now().hour}:${DateTime.now().minute}";

      await _cloudStoreDataManagement.sendMessageToConnection(
          connectionUserName: widget.userName,
          sendMessageData: {
            ChatMessageTypes.Text.toString(): {
              chatController.text: _messageTime,
            },
          },
          chatMessageTypes: ChatMessageTypes.Text);

      if (mounted) {
        setState(() {
          _allConversationMessages.add({
            chatController.text: _messageTime,
          });
          _chatMessageCategoryHolder.add(ChatMessageTypes.Text);
          _conversationMessageHolder.add(false);
        });
      }

      if (mounted) {
        setState(() {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent +
                _amountToScroll(ChatMessageTypes.Text) +
                30.0,
          );
        });
      }

      await _localDatabase.insertMessageInUserTable(
          userName: widget.userName,
          actualMessage: chatController.text,
          chatMessageTypes: ChatMessageTypes.Text,
          messageHolderType: MessageHolderType.Me,
          messageDateLocal: DateTime.now().toString().split(" ")[0],
          messageTimeLocal: _messageTime);

      if (mounted) {
        setState(() {
          chatController.clear();
          _isLoading = false;
          textpresent = false;
        });
      }
    }
  }

  Widget _textConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          margin: _conversationMessageHolder[index]
              ? EdgeInsets.only(
                  right: MediaQuery.of(context).size.width / 3,
                  left: 5.0,
                )
              : EdgeInsets.only(
                  left: MediaQuery.of(context).size.width / 3,
                  right: 5.0,
                ),
          alignment: _conversationMessageHolder[index]
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: _conversationMessageHolder[index]
                  ? Color.fromRGBO(60, 80, 100, 1)
                  : Color.fromRGBO(102, 102, 255, 1),
              elevation: 0.0,
              padding: EdgeInsets.all(10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: _conversationMessageHolder[index]
                      ? Radius.circular(0.0)
                      : Radius.circular(20.0),
                  topRight: _conversationMessageHolder[index]
                      ? Radius.circular(20.0)
                      : Radius.circular(0.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
            ),
            child: Text(
              _allConversationMessages[index].keys.first,
              style: TextStyle(fontSize: 16.0, color: Colors.white),
            ),
            onPressed: () {},
            onLongPress: () {},
          ),
        ),
        _conversationMessageTime(
            _allConversationMessages[index].values.first, index),
      ],
    );
  }

  Widget _conversationMessageTime(String time, int index) {
    return Container(
      alignment: _conversationMessageHolder[index]
          ? Alignment.centerLeft
          : Alignment.centerRight,
      margin: _conversationMessageHolder[index]
          ? const EdgeInsets.only(
              left: 5.0,
              bottom: 5.0,
              top: 5.0,
            )
          : const EdgeInsets.only(
              right: 5.0,
              bottom: 5.0,
              top: 5.0,
            ),
      child: _timeReFormat(time),
    );
  }

  Widget _timeReFormat(String _willReturnTime) {
    if (int.parse(_willReturnTime.split(':')[0]) < 10)
      _willReturnTime = _willReturnTime.replaceRange(
          0, _willReturnTime.indexOf(':'), '0${_willReturnTime.split(':')[0]}');

    if (int.parse(_willReturnTime.split(':')[1]) < 10)
      _willReturnTime = _willReturnTime.replaceRange(
          _willReturnTime.indexOf(':') + 1,
          _willReturnTime.length,
          '0${_willReturnTime.split(':')[1]}');

    return Text(
      _willReturnTime,
      style: const TextStyle(color: Colors.lightBlue),
    );
  }

  void chatOptions() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40.0),
              ),
              elevation: 0.3,
              backgroundColor: Color.fromRGBO(34, 48, 60, 0.5),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.7,
                child: Center(
                  child: CircleList(
                    initialAngle: 55,
                    outerRadius: MediaQuery.of(context).size.width / 3.2,
                    innerRadius: MediaQuery.of(context).size.width / 10,
                    showInitialAnimation: true,
                    innerCircleColor: Color.fromRGBO(34, 48, 60, 1),
                    outerCircleColor: Color.fromRGBO(0, 0, 0, 0.1),
                    origin: Offset(0, 0),
                    rotateMode: RotateMode.allRotate,
                    centerWidget: Center(
                      child: Text(
                        "Share",
                        style: TextStyle(
                          color: Colors.lightBlue,
                          fontSize: 45.0,
                        ),
                      ),
                    ),
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            )),
                        child: GestureDetector(
                          onTap: () async {
                            final pickedImage = await ImagePicker().pickImage(
                                source: ImageSource.camera, imageQuality: 50);
                            if (pickedImage != null) {
                              _addSelectedMediaToChat(pickedImage.path);
                            }
                          },
                          onLongPress: () async {
                            final XFile? pickedImage = await ImagePicker()
                                .pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 50);
                            if (pickedImage != null) {
                              _addSelectedMediaToChat(pickedImage.path);
                            }
                          },
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            )),
                        child: GestureDetector(
                          onTap: () async {
                            //   if (mounted) {
                            //     setState(() {
                            //       _isLoading = true;
                            //     });
                            //   }

                            //   final pickedVideo = await ImagePicker().pickVideo(
                            //       source: ImageSource.camera,
                            //       maxDuration: Duration(seconds: 15));

                            //   if (pickedVideo != null) {
                            //     final String thumbnailPathTake =
                            //         await _nativeCallback.getTheVideoThumbnail(
                            //             videoPath: pickedVideo.path);

                            //     _addSelectedMediaToChat(pickedVideo.path,
                            //         chatMessageTypeTake: ChatMessageTypes.Video,
                            //         thumbnailPath: thumbnailPathTake);
                            //   }

                            //   if (mounted) {
                            //     setState(() {
                            //       _isLoading = false;
                            //     });
                            //   }
                            // },
                            // onLongPress: () async {
                            //   if (mounted) {
                            //     setState(() {
                            //       _isLoading = true;
                            //     });
                            //   }

                            //   final pickedVideo = await ImagePicker().pickVideo(
                            //       source: ImageSource.gallery,
                            //       maxDuration: Duration(seconds: 15));

                            //   if (pickedVideo != null) {
                            //     final String thumbnailPathTake =
                            //         await _nativeCallback.getTheVideoThumbnail(
                            //             videoPath: pickedVideo.path);

                            //     _addSelectedMediaToChat(pickedVideo.path,
                            //         chatMessageTypeTake: ChatMessageTypes.Video,
                            //         thumbnailPath: thumbnailPathTake);
                            //   }

                            //   if (mounted) {
                            //     setState(() {
                            //       _isLoading = false;
                            //     });
                            //   }
                          },
                          child: Icon(
                            Icons.video_collection,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            )),
                        child: GestureDetector(
                          onTap: () async {
                            await _pickFileFromStorage();
                          },
                          child: Icon(
                            Icons.document_scanner_outlined,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            )),
                        child: GestureDetector(
                          onTap: () async {
                            final PermissionStatus locationPermissionStatus =
                                await Permission.location.request();
                            if (locationPermissionStatus ==
                                PermissionStatus.granted) {
                              await _takeLocationInput();
                            } else {
                              showToast(
                                  "Location Permission Required", _fToast);
                            }
                          },
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            )),
                        child: GestureDetector(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Colors.lightGreen,
                          ),
                          onTap: () async {
                            final List<String> _allowedExtensions = const [
                              'mp3',
                              'm4a',
                              'wav',
                              'ogg',
                            ];

                            final FilePickerResult? _audioFilePickerResult =
                                await FilePicker.platform.pickFiles(
                              type: FileType.audio,
                            );

                            Navigator.pop(context);

                            if (_audioFilePickerResult != null) {
                              _audioFilePickerResult.files.forEach((element) {
                                print('Name: ${element.path}');
                                print('Extension: ${element.extension}');
                                if (_allowedExtensions
                                    .contains(element.extension)) {
                                  _voiceAndAudioSend(element.path.toString(),
                                      audioExtension: '.${element.extension}');
                                } else {
                                  _voiceAndAudioSend(element.path.toString());
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }

  void _voiceAndAudioSend(String recordedFilePath,
      {String audioExtension = '.mp3'}) async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (_justAudioPlayer.duration != null) {
      if (mounted) {
        setState(() {
          _justAudioPlayer.stop();
          _iconData = Icons.play_arrow_rounded;
        });
      }
    }

    await _justAudioPlayer.setFilePath(recordedFilePath);

    if (_justAudioPlayer.duration!.inMinutes > 20)
      showToast(
          "Audio File Duration Can't be greater than 20 minutes", _fToast);
    else {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      final String _messageTime =
          "${DateTime.now().hour}:${DateTime.now().minute}";

      final String? downloadedVoicePath = await _cloudStoreDataManagement
          .uploadMediaToStorage(File(recordedFilePath),
              reference: 'chatVoices/');

      if (downloadedVoicePath != null) {
        await _cloudStoreDataManagement.sendMessageToConnection(
            chatMessageTypes: ChatMessageTypes.Audio,
            connectionUserName: widget.userName,
            sendMessageData: {
              ChatMessageTypes.Audio.toString(): {
                downloadedVoicePath.toString(): _messageTime
              }
            });

        if (mounted) {
          setState(() {
            _allConversationMessages.add({
              recordedFilePath: _messageTime,
            });
            _chatMessageCategoryHolder.add(ChatMessageTypes.Audio);
            _conversationMessageHolder.add(false);
          });
        }

        if (mounted) {
          setState(() {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent +
                  _amountToScroll(ChatMessageTypes.Audio) +
                  30.0,
            );
          });
        }

        await _localDatabase.insertMessageInUserTable(
            userName: widget.userName,
            actualMessage: recordedFilePath.toString(),
            chatMessageTypes: ChatMessageTypes.Audio,
            messageHolderType: MessageHolderType.Me,
            messageDateLocal: DateTime.now().toString().split(" ")[0],
            messageTimeLocal: _messageTime);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _takeLocationInput() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);

      final Marker marker = Marker(
          markerId: MarkerId('locate'),
          zIndex: 1.0,
          draggable: true,
          position: LatLng(position.latitude, position.longitude));

      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                backgroundColor: Colors.black26,
                actions: [
                  FloatingActionButton(
                    child: Icon(Icons.send),
                    onPressed: () async {
                      Navigator.pop(context);
                      Navigator.pop(context);

                      if (mounted) {
                        setState(() {
                          this._isLoading = true;
                        });
                      }

                      final String _messageTime =
                          "${DateTime.now().hour}:${DateTime.now().minute}";

                      await _cloudStoreDataManagement.sendMessageToConnection(
                          chatMessageTypes: ChatMessageTypes.Location,
                          connectionUserName: widget.userName,
                          sendMessageData: {
                            ChatMessageTypes.Location.toString(): {
                              "${position.latitude}+${position.longitude}":
                                  _messageTime,
                            },
                          });

                      if (mounted) {
                        setState(() {
                          this._allConversationMessages.add({
                            "${position.latitude}+${position.longitude}":
                                _messageTime,
                          });

                          this
                              ._chatMessageCategoryHolder
                              .add(ChatMessageTypes.Location);
                          this._conversationMessageHolder.add(false);
                        });
                      }

                      if (mounted) {
                        setState(() {
                          _scrollController.jumpTo(
                            _scrollController.position.maxScrollExtent +
                                _amountToScroll(ChatMessageTypes.Location),
                          );
                        });
                      }

                      await _localDatabase.insertMessageInUserTable(
                          userName: widget.userName,
                          actualMessage:
                              "${position.latitude}+${position.longitude}",
                          chatMessageTypes: ChatMessageTypes.Location,
                          messageHolderType: MessageHolderType.Me,
                          messageDateLocal:
                              DateTime.now().toString().split(" ")[0],
                          messageTimeLocal: _messageTime);

                      if (mounted) {
                        setState(() {
                          this._isLoading = false;
                        });
                      }
                    },
                  ),
                ],
                content: FittedBox(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                    ),
                    child: GoogleMap(
                      mapType: MapType.hybrid,
                      markers: Set.of([marker]),
                      initialCameraPosition: CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 18.4746,
                      ),
                    ),
                  ),
                ),
              ));
    } catch (e) {
      print('Map Show Error: ${e.toString()}');
      showToast('Map Show Error', this._fToast,
          toastColor: Colors.red, fontSize: 16.0);
    }
  }

  Widget _mediaConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 0.3,
            margin: _conversationMessageHolder[index]
                ? EdgeInsets.only(
                    right: MediaQuery.of(context).size.width / 3,
                    left: 5.0,
                    top: 30.0,
                  )
                : EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 3,
                    right: 5.0,
                    top: 15.0,
                  ),
            alignment: _conversationMessageHolder[index]
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: OpenContainer(
              openColor: const Color.fromRGBO(60, 80, 100, 1),
              closedColor: _conversationMessageHolder[index]
                  ? const Color.fromRGBO(60, 80, 100, 1)
                  : const Color.fromRGBO(102, 102, 255, 1),
              middleColor: Color.fromRGBO(60, 80, 100, 1),
              closedElevation: 0.0,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              transitionDuration: Duration(
                milliseconds: 400,
              ),
              transitionType: ContainerTransitionType.fadeThrough,
              openBuilder: (context, openWidget) {
                return ImageViewScreen(
                  imagePath: _chatMessageCategoryHolder[index] ==
                          ChatMessageTypes.Image
                      ? _allConversationMessages[index].keys.first
                      : _allConversationMessages[index]
                          .keys
                          .first
                          .split("+")[0],
                  imageProviderCategory: ImageProviderCategory.FileImage,
                );
              },
              closedBuilder: (context, closeWidget) => Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: PhotoView(
                      imageProvider: FileImage(File(
                          _chatMessageCategoryHolder[index] ==
                                  ChatMessageTypes.Image
                              ? _allConversationMessages[index].keys.first
                              : _allConversationMessages[index]
                                  .keys
                                  .first
                                  .split("+")[0])),
                      loadingBuilder: (context, event) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorBuilder: (context, obj, stackTrace) => Center(
                          child: Text(
                        'Image not Found',
                        style: TextStyle(
                          fontSize: 23.0,
                          color: Colors.red,
                          fontFamily: 'Lora',
                          letterSpacing: 1.0,
                        ),
                      )),
                      enableRotation: true,
                      minScale: PhotoViewComputedScale.covered,
                    ),
                  ),
                  if (_chatMessageCategoryHolder[index] ==
                      ChatMessageTypes.Video)
                    Center(
                      child: IconButton(
                        iconSize: 100.0,
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          print(
                              "Opening Path is: ${_allConversationMessages[index].keys.first.split("+")[1]}");

                          final OpenResult openResult = await OpenFile.open(
                              _allConversationMessages[index]
                                  .keys
                                  .first
                                  .split("+")[1]);

                          openFileResultStatus(openResult: openResult);
                        },
                      ),
                    ),
                ],
              ),
            )),
        _conversationMessageTime(
            _allConversationMessages[index].values.first.split("+")[0], index),
      ],
    );
  }

  void openFileResultStatus({required OpenResult openResult}) {
    if (openResult.type == ResultType.permissionDenied)
      showToast('Permission Denied to Open File', _fToast,
          toastColor: Colors.red, fontSize: 16.0);
    else if (openResult.type == ResultType.noAppToOpen)
      showToast('No App Found to Open', _fToast,
          toastColor: Colors.amber, fontSize: 16.0);
    else if (openResult.type == ResultType.error)
      showToast('Error in Opening File', _fToast,
          toastColor: Colors.red, fontSize: 16.0);
    else if (openResult.type == ResultType.fileNotFound)
      showToast('Sorry, File Not Found', _fToast,
          toastColor: Colors.red, fontSize: 16.0);
  }

  _takePermissionForStorage() async {
    var status = await Permission.storage.request();
    if (status == PermissionStatus.granted) {
      {
        // showToast("Thanks For Storage Permission", _fToast,
        //     toastColor: Colors.green, fontSize: 16.0);

        _makeDirectoryForRecordings();
      }
    } else {
      showToast("Some Problem May Be Arrive", _fToast,
          toastColor: Colors.green, fontSize: 16.0);
    }
  }

  _makeDirectoryForRecordings() async {
    final Directory? directory = await getExternalStorageDirectory();

    _audioDirectory = await Directory(directory!.path + '/Recordings/')
        .create(); // This directory will create Once in whole Application
  }

  void _addSelectedMediaToChat(String path,
      {ChatMessageTypes chatMessageTypeTake = ChatMessageTypes.Image,
      String thumbnailPath = ''}) {
    Navigator.pop(context);

    print('Thumbnail Path: $thumbnailPath    ${File(path).path}');

    final String _messageTime =
        "${DateTime.now().hour}:${DateTime.now().minute}";

    if (mounted) {
      setState(() {
        _allConversationMessages.add({
          chatMessageTypeTake == ChatMessageTypes.Image
              ? File(path).path
              : "$thumbnailPath+${File(path).path}": _messageTime,
        });

        _chatMessageCategoryHolder.add(
            chatMessageTypeTake == ChatMessageTypes.Image
                ? ChatMessageTypes.Image
                : ChatMessageTypes.Video);

        _conversationMessageHolder.add(false);
      });
    }

    if (mounted) {
      setState(() {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent +
              _amountToScroll(chatMessageTypeTake),
        );
      });
    }

    if (chatMessageTypeTake == ChatMessageTypes.Image)
      _sendImage(File(path).path);
    else {
      _sendVideo(videoPath: File(path).path, thumbnailPath: thumbnailPath);
    }
  }

  Future<void> _sendVideo(
      {required String videoPath, required thumbnailPath}) async {
    if (mounted) {
      setState(() {
        this._isLoading = true;
      });
    }

    final String _messageTime =
        "${DateTime.now().hour}:${DateTime.now().minute}";

    final String? downloadedVideoPath = await _cloudStoreDataManagement
        .uploadMediaToStorage(File(videoPath), reference: 'chatVideos/');

    final String? downloadedVideoThumbnailPath = await _cloudStoreDataManagement
        .uploadMediaToStorage(File(thumbnailPath),
            reference: 'chatVideosThumbnail/');

    if (downloadedVideoPath != null) {
      await _cloudStoreDataManagement.sendMessageToConnection(
          connectionUserName: widget.userName,
          sendMessageData: {
            ChatMessageTypes.Video.toString(): {
              "${downloadedVideoPath.toString()}+${downloadedVideoThumbnailPath.toString()}":
                  _messageTime
            }
          },
          chatMessageTypes: ChatMessageTypes.Video);

      await _localDatabase.insertMessageInUserTable(
          userName: widget.userName,
          actualMessage: downloadedVideoPath.toString() +
              downloadedVideoThumbnailPath.toString(),
          chatMessageTypes: ChatMessageTypes.Video,
          messageHolderType: MessageHolderType.Me,
          messageDateLocal: DateTime.now().toString().split(" ")[0],
          messageTimeLocal: _messageTime);
    }

    if (mounted) {
      setState(() {
        this._isLoading = false;
      });
    }
  }

  Future<void> _sendImage(String imageFilePath) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final String _messageTime =
        "${DateTime.now().hour}:${DateTime.now().minute}";

    final String? downloadedImagePath = await _cloudStoreDataManagement
        .uploadMediaToStorage(File(imageFilePath), reference: 'chatImages/');

    if (downloadedImagePath != null) {
      await _cloudStoreDataManagement.sendMessageToConnection(
          chatMessageTypes: ChatMessageTypes.Image,
          connectionUserName: widget.userName,
          sendMessageData: {
            ChatMessageTypes.Image.toString(): {
              downloadedImagePath.toString(): _messageTime
            }
          });

      await _localDatabase.insertMessageInUserTable(
          userName: widget.userName,
          actualMessage: imageFilePath,
          chatMessageTypes: ChatMessageTypes.Image,
          messageHolderType: MessageHolderType.Me,
          messageDateLocal: DateTime.now().toString().split(" ")[0],
          messageTimeLocal: _messageTime);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _locationConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
        ),
        height: MediaQuery.of(context).size.height * 0.3,
        margin: this._conversationMessageHolder[index]
            ? EdgeInsets.only(
                right: MediaQuery.of(context).size.width / 3,
                left: 5.0,
                top: 30.0,
              )
            : EdgeInsets.only(
                left: MediaQuery.of(context).size.width / 3,
                right: 5.0,
                top: 15.0,
              ),
        alignment: this._conversationMessageHolder[index]
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: GoogleMap(
          mapType: MapType.hybrid,
          markers: Set.of([
            Marker(
                markerId: MarkerId('locate'),
                zIndex: 1.0,
                draggable: true,
                position: LatLng(
                    double.parse(this
                        ._allConversationMessages[index]
                        .keys
                        .first
                        .split('+')[0]),
                    double.parse(this
                        ._allConversationMessages[index]
                        .keys
                        .first
                        .split('+')[1])))
          ]),
          initialCameraPosition: CameraPosition(
            target: LatLng(
                double.parse(this
                    ._allConversationMessages[index]
                    .keys
                    .first
                    .split('+')[0]),
                double.parse(this
                    ._allConversationMessages[index]
                    .keys
                    .first
                    .split('+')[1])),
            zoom: 17.4746,
          ),
        ),
      ),
      _conversationMessageTime(
          this._allConversationMessages[index].values.first, index),
    ]);
  }

  Widget _documentConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(
      children: [
        Container(
            height: _allConversationMessages[index].keys.first.contains('.pdf')
                ? MediaQuery.of(context).size.height * 0.3
                : 70.0,
            margin: _conversationMessageHolder[index]
                ? EdgeInsets.only(
                    right: MediaQuery.of(context).size.width / 3,
                    left: 5.0,
                    top: 30.0,
                  )
                : EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 3,
                    right: 5.0,
                    top: 15.0,
                  ),
            alignment: _conversationMessageHolder[index]
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color:
                    _allConversationMessages[index].keys.first.contains('.pdf')
                        ? Colors.white
                        : _conversationMessageHolder[index]
                            ? const Color.fromRGBO(60, 80, 100, 1)
                            : const Color.fromRGBO(102, 102, 255, 1),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: _allConversationMessages[index].keys.first.contains('.pdf')
                  ? Stack(
                      children: [
                        Center(
                            child: Text(
                          'Loading Error',
                          style: TextStyle(
                            fontFamily: 'Lora',
                            color: Colors.red,
                            fontSize: 20.0,
                            letterSpacing: 1.0,
                          ),
                        )),
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: PdfView(
                            path: _allConversationMessages[index].keys.first,
                          ),
                        ),
                        Center(
                          child: GestureDetector(
                            child: Icon(
                              Icons.open_in_new_rounded,
                              size: 40.0,
                              color: Colors.blue,
                            ),
                            onTap: () async {
                              final OpenResult openResult = await OpenFile.open(
                                  _allConversationMessages[index].keys.first);

                              openFileResultStatus(openResult: openResult);
                            },
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () async {
                        final OpenResult openResult = await OpenFile.open(
                            _allConversationMessages[index].keys.first);

                        openFileResultStatus(openResult: openResult);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 20.0,
                          ),
                          Icon(
                            Icons.document_scanner,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 20.0,
                          ),
                          Expanded(
                            child: Text(
                              _allConversationMessages[index]
                                  .keys
                                  .first
                                  .split("/")
                                  .last,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Lora',
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            )),
        _conversationMessageTime(
            _allConversationMessages[index].values.first, index),
      ],
    );
  }

  Future<void> _pickFileFromStorage() async {
    List<String> _allowedExtensions = [
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'c',
      'cpp',
      'py',
      'text'
    ];

    try {
      if (!await Permission.storage.isGranted) _takePermissionForStorage();

      final FilePickerResult? filePickerResult =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (filePickerResult != null && filePickerResult.files.length > 0) {
        Navigator.pop(context);

        filePickerResult.files.forEach((file) async {
          print(file.path);

          if (_allowedExtensions.contains(file.extension)) {
            if (mounted) {
              setState(() {
                this._isLoading = true;
              });
            }

            final String _messageTime =
                "${DateTime.now().hour}:${DateTime.now().minute}";

            final String? downloadedDocumentPath =
                await _cloudStoreDataManagement.uploadMediaToStorage(
                    File(File(file.path.toString()).path),
                    reference: 'chatDocuments/');

            if (downloadedDocumentPath != null) {
              await _cloudStoreDataManagement.sendMessageToConnection(
                  chatMessageTypes: ChatMessageTypes.Document,
                  connectionUserName: widget.userName,
                  sendMessageData: {
                    ChatMessageTypes.Document.toString(): {
                      "${downloadedDocumentPath.toString()}+.${file.extension}":
                          _messageTime
                    }
                  });

              if (mounted) {
                setState(() {
                  this._allConversationMessages.add({
                    File(file.path.toString()).path: _messageTime,
                  });

                  this
                      ._chatMessageCategoryHolder
                      .add(ChatMessageTypes.Document);
                  this._conversationMessageHolder.add(false);
                });
              }

              if (mounted) {
                setState(() {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent +
                        _amountToScroll(ChatMessageTypes.Document),
                  );
                });
              }

              await _localDatabase.insertMessageInUserTable(
                  userName: widget.userName,
                  actualMessage: File(file.path.toString()).path.toString(),
                  chatMessageTypes: ChatMessageTypes.Document,
                  messageHolderType: MessageHolderType.Me,
                  messageDateLocal: DateTime.now().toString().split(" ")[0],
                  messageTimeLocal: _messageTime);
            }

            if (mounted) {
              setState(() {
                this._isLoading = false;
              });
            }
          } else {
            showToast(
              'Not Supporting Document Format',
              this._fToast,
              toastColor: Colors.red,
              fontSize: 16.0,
            );
          }
        });
      }
    } catch (e) {
      showToast(
        'Some Error Happened',
        this._fToast,
        toastColor: Colors.red,
        fontSize: 16.0,
      );
    }
  }

  void chatMicrophoneOnTapAction(int index) async {
    try {
      _justAudioPlayer.positionStream.listen((event) {
        if (mounted) {
          setState(() {
            _currAudioPlayingTime = event.inMicroseconds.ceilToDouble();
            _loadingTime =
                '${event.inMinutes} : ${event.inSeconds > 59 ? event.inSeconds % 60 : event.inSeconds}';
          });
        }
      });

      _justAudioPlayer.playerStateStream.listen((event) {
        if (event.processingState == ProcessingState.completed) {
          _justAudioPlayer.stop();
          if (mounted) {
            setState(() {
              _loadingTime = '0:00';
              _iconData = Icons.play_arrow_rounded;
            });
          }
        }
      });

      if (_lastAudioPlayingIndex != index) {
        await _justAudioPlayer
            .setFilePath(_allConversationMessages[index].keys.first);

        if (mounted) {
          setState(() {
            _lastAudioPlayingIndex = index;
            _totalDuration =
                '${_justAudioPlayer.duration!.inMinutes} : ${_justAudioPlayer.duration!.inSeconds > 59 ? _justAudioPlayer.duration!.inSeconds % 60 : _justAudioPlayer.duration!.inSeconds}';
            _iconData = Icons.pause;
            _audioPlayingSpeed = 1.0;
            _justAudioPlayer.setSpeed(_audioPlayingSpeed);
          });
        }

        await _justAudioPlayer.play();
      } else {
        print(_justAudioPlayer.processingState);
        if (_justAudioPlayer.processingState == ProcessingState.idle) {
          await _justAudioPlayer
              .setFilePath(_allConversationMessages[index].keys.first);

          if (mounted) {
            setState(() {
              _lastAudioPlayingIndex = index;
              _totalDuration =
                  '${_justAudioPlayer.duration!.inMinutes} : ${_justAudioPlayer.duration!.inSeconds}';
              _iconData = Icons.pause;
            });
          }

          await _justAudioPlayer.play();
        } else if (_justAudioPlayer.playing) {
          if (mounted) {
            setState(() {
              _iconData = Icons.play_arrow_rounded;
            });
          }

          await _justAudioPlayer.pause();
        } else if (_justAudioPlayer.processingState == ProcessingState.ready) {
          if (mounted) {
            setState(() {
              _iconData = Icons.pause;
            });
          }

          await _justAudioPlayer.play();
        } else if (_justAudioPlayer.processingState ==
            ProcessingState.completed) {}
      }
    } catch (e) {
      print('Audio Playing Error');
      showToast('May be Audio File Not Found', _fToast);
    }
  }

  double _amountToScroll(ChatMessageTypes chatMessageTypes,
      {String? actualMessageKey}) {
    switch (chatMessageTypes) {
      case ChatMessageTypes.None:
        return 10.0 + 30.0;
      case ChatMessageTypes.Text:
        return 10.0 + 30.0;
      case ChatMessageTypes.Image:
        return MediaQuery.of(context).size.height * 0.6;
      case ChatMessageTypes.Video:
        return MediaQuery.of(context).size.height * 0.6;
      case ChatMessageTypes.Document:
        return MediaQuery.of(context).size.height * 0.6;
      case ChatMessageTypes.Audio:
        return 70.0 + 30.0;
      case ChatMessageTypes.Location:
        return MediaQuery.of(context).size.height * 0.6;
    }
  }
}
