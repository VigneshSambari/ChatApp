import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class NativeCallback {
  static const MethodChannel _platform =
      const MethodChannel('com.youtubetutorial.generation/nativeCallBack');

  Future<String> getTheVideoThumbnail({required String videoPath}) async {
    print('Thumbnail Take');

    final thumbnailPath = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth:
          128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    );
    return thumbnailPath.toString();
  }
}
