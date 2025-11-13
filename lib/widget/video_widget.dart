import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoAdvWidget extends StatefulWidget {
  final dynamic url;
  final double width;
  final double? height;

  const VideoAdvWidget({
    super.key,
    this.height,
    this.width = 140,
    required this.url,
  });

  @override
  VideoAdvWidgetState createState() => VideoAdvWidgetState();
}

class VideoAdvWidgetState extends State<VideoAdvWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = widget.url is File
        ? VideoPlayerController.file(widget.url)
        : VideoPlayerController.network(widget.url);

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.play();
    _controller.setLooping(true);
    _controller.setVolume(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? MediaQuery.of(context).size.height,
      child: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  VideoPlayer(_controller),
                  Center(
                    child: InkWell(
                      onTap: () {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                        setState(() {});
                      },
                      child: SizedBox(width: 100, height: 100),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
