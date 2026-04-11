import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';

/// Widget that displays a video thumbnail
/// If thumbnailUrl is provided, shows that image
/// Otherwise, generates thumbnail from video URL using video player
class VideoThumbnailWidget extends StatefulWidget {
  final String? thumbnailUrl;
  final String videoUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool generateFromVideo;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    required this.videoUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.generateFromVideo = false,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _thumbnailController;
  bool _isGeneratingThumbnail = false;
  bool _thumbnailGenerated = false;

  @override
  void initState() {
    super.initState();
    // If no thumbnail URL provided, generate from video
    if (widget.generateFromVideo &&
        (widget.thumbnailUrl == null || widget.thumbnailUrl!.isEmpty)) {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    if (_isGeneratingThumbnail || _thumbnailGenerated) return;

    setState(() {
      _isGeneratingThumbnail = true;
    });

    try {
      // Use URL as-is (keep encoded) - Uri.parse handles encoded URLs correctly
      String videoUrl = widget.videoUrl.trim();

      _thumbnailController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _thumbnailController!.initialize();

      // Seek to first frame (0 seconds)
      await _thumbnailController!.seekTo(Duration.zero);
      await _thumbnailController!.pause();

      if (mounted) {
        setState(() {
          _thumbnailGenerated = true;
          _isGeneratingThumbnail = false;
        });
      }
    } catch (e) {
      log(
        "VideoThumbnail: Error generating thumbnail: $e",
        name: "VideoThumbnail",
      );
      if (mounted) {
        setState(() {
          _isGeneratingThumbnail = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _thumbnailController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If thumbnail URL is provided, use NetworkImageWidget
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return NetworkImageWidget(
        imageUrl: widget.thumbnailUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      );
    }

    // Otherwise, use video player to show first frame
    if (_isGeneratingThumbnail) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_thumbnailGenerated &&
        _thumbnailController != null &&
        _thumbnailController!.value.isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _thumbnailController!.value.size.width,
            height: _thumbnailController!.value.size.height,
            child: VideoPlayer(_thumbnailController!),
          ),
        ),
      );
    }

    // Fallback: show placeholder
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: const Icon(Icons.videocam, color: Colors.white54, size: 40),
    );
  }
}
