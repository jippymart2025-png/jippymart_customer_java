import 'dart:async';
import 'dart:convert';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryVideo extends StatefulWidget {
  final String rawUrl;
  final bool autoPlay;
  final bool looping;

  const StoryVideo.url(
    this.rawUrl, {
    Key? key,
    this.autoPlay = true,
    this.looping = false,
  }) : super(key: key);

  @override
  State<StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  String? _cleanUrl;
  String? _errorText;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    setState(() {
      _initializing = true;
      _errorText = null;
    });

    try {
      final url = _extractUrl(widget.rawUrl);
      if (url.isEmpty) throw Exception("Invalid URL");

      _cleanUrl = url;
      _videoController = VideoPlayerController.network(
        _cleanUrl!,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        allowFullScreen: true,
        // ENABLE FULL SCREEN
        allowedScreenSleep: false,
        // Prevent screen turning off
        allowMuting: true,
        // Optional
        showControls: true,
        // Make sure controls are visible
        fullScreenByDefault: false, // Don't auto fullscreen, user clicks button
      );

      if (widget.autoPlay) {
        _videoController!.play();
      }

      setState(() => _initializing = false);
    } catch (e) {
      setState(() {
        _initializing = false;
        _errorText = e.toString();
      });
    }
  }

  /// Clean raw Firestore value → extract proper https URL
  String _extractUrl(String raw) {
    var s = raw.trim();

    // If stored as ["url"]
    if (s.startsWith('[') && s.endsWith(']')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString();
        }
      } catch (_) {}
    }

    // Remove surrounding quotes
    if (s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1);
    }

    // UNIVERSAL SAFE REGEX (no quotes, no escape issues)
    final reg = RegExp(r'(https?:\/\/[^\s]+)');
    final match = reg.firstMatch(s);

    if (match != null) return match.group(0)!;

    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorText != null) {
      return Center(child: Text("Video Error: $_errorText"));
    }
    if (_chewieController == null) {
      return const SizedBox.shrink();
    }
    return
    // AspectRatio(
    // aspectRatio: _videoController!.value.aspectRatio == 0
    //     ? 16 / 5
    //     : _videoController!.value.aspectRatio,
    // child:
    Chewie(controller: _chewieController!);
    // );
  }
}
