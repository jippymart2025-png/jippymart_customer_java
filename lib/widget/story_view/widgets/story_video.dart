import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:jippymart_customer/app/home_screen/screen/story_view_screen/provider/story_provider.dart';

class StoryVideo extends StatefulWidget {
  final String rawUrl;
  final bool autoPlay;
  final bool looping;
  final StoryProvider? controller;

  const StoryVideo.url(
    this.rawUrl, {
    Key? key,
    this.autoPlay = true,
    this.looping = false,
    this.controller,
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
  StreamSubscription<PlaybackState>? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _setupPlaybackListener() {
    // Set up playback listener after video is initialized
    if (widget.controller != null && _playbackSubscription == null) {
      _playbackSubscription = widget.controller!.playbackNotifier.listen((playbackState) {
        if (!mounted || _videoController == null || !_videoController!.value.isInitialized) {
          return;
        }

        switch (playbackState) {
          case PlaybackState.pause:
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            }
            break;
          case PlaybackState.play:
            if (!_videoController!.value.isPlaying) {
              _videoController!.play();
            }
            break;
          case PlaybackState.next:
          case PlaybackState.previous:
            // Handle navigation if needed
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
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
      if (url.isEmpty) {
        log(
          "StoryVideo: Invalid or empty URL from raw: ${widget.rawUrl}",
          name: "StoryVideo",
        );
        throw Exception("Invalid URL: Unable to extract video URL");
      }

      _cleanUrl = url;
      log(
        "StoryVideo: Extracted URL: $_cleanUrl",
        name: "StoryVideo",
      );

      // Validate URL format (URL is already decoded by _extractUrl)
      try {
        final uri = Uri.parse(_cleanUrl!);
        if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
          throw Exception("Invalid URL scheme: ${uri.scheme}");
        }
      } catch (e) {
        log(
          "StoryVideo: URL validation error: $e",
          name: "StoryVideo",
        );
        throw Exception("Invalid URL format: $_cleanUrl");
      }

      // Parse URI properly - Uri.parse handles both encoded and unencoded URLs
      Uri videoUri;
      try {
        videoUri = Uri.parse(_cleanUrl!);
        // Validate the URI
        if (!videoUri.hasScheme || !videoUri.hasAuthority) {
          throw Exception("Invalid URI structure");
        }
      } catch (e) {
        log(
          "StoryVideo: URI parse error: $e, trying to fix URL",
          name: "StoryVideo",
        );
        // If parsing fails, try to construct URI manually
        try {
          // Try to extract scheme, host, and path
          final urlPattern = RegExp(r'(https?://)([^/]+)(.*)');
          final match = urlPattern.firstMatch(_cleanUrl!);
          if (match != null) {
            final scheme = match.group(1)!.replaceAll('://', '');
            final authority = match.group(2)!;
            final path = match.group(3) ?? '';
            videoUri = Uri(scheme: scheme, host: authority, path: path);
          } else {
            throw Exception("Could not parse URL: $_cleanUrl");
          }
        } catch (e2) {
          throw Exception("Failed to parse URL: $_cleanUrl - $e2");
        }
      }

      log(
        "StoryVideo: Creating video controller for: $videoUri",
        name: "StoryVideo",
      );

      _videoController = VideoPlayerController.networkUrl(
        videoUri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      // Initialize with timeout
      await _videoController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Video initialization timeout");
        },
      );

      log(
        "StoryVideo: Video initialized successfully. Duration: ${_videoController!.value.duration}, Size: ${_videoController!.value.size}",
        name: "StoryVideo",
      );

      // Check if video is actually playable
      if (!_videoController!.value.isInitialized) {
        throw Exception("Video failed to initialize");
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false, // Don't auto-play, let StoryProvider control it
        looping: widget.looping,
        allowFullScreen: true,
        allowedScreenSleep: false,
        allowMuting: true,
        showControls: false, // Hide controls for story view
        fullScreenByDefault: false,
        errorBuilder: (context, errorMessage) {
          log(
            "StoryVideo: Chewie error: $errorMessage",
            name: "StoryVideo",
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Video Error",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Set up playback listener now that video is initialized
      _setupPlaybackListener();

      // Wait a bit then start playing if autoPlay is enabled and controller allows
      if (widget.autoPlay && _videoController!.value.isInitialized) {
        // Small delay to ensure everything is set up
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && _videoController != null && _videoController!.value.isInitialized) {
          // Start playing the video
          await _videoController!.play();
          // Then let StoryProvider know to play (this will keep it playing)
          widget.controller?.play();
          log(
            "StoryVideo: Video ready and playing. Duration: ${_videoController!.value.duration}, Size: ${_videoController!.value.size}, IsPlaying: ${_videoController!.value.isPlaying}",
            name: "StoryVideo",
          );
        }
      }

      setState(() => _initializing = false);
    } catch (e) {
      log(
        "StoryVideo: Error initializing video: $e",
        name: "StoryVideo",
      );
      setState(() {
        _initializing = false;
        _errorText = e.toString();
      });
    }
  }

  /// Clean raw Firestore value → extract proper https URL
  /// Handles both Firebase storage URLs and direct MP4 URLs
  String _extractUrl(String raw) {
    if (raw.isEmpty) {
      log("StoryVideo: Empty raw URL", name: "StoryVideo");
      return '';
    }

    var s = raw.trim();
    log("StoryVideo: Extracting URL from: $s", name: "StoryVideo");

    // If already a valid URL (starts with http:// or https://), return as is
    // Keep URL encoded (don't decode) as HTTP requests need encoded URLs
    if (s.startsWith('http://') || s.startsWith('https://')) {
      try {
        // First, try to parse the URL directly
        final uri = Uri.tryParse(s);
        if (uri != null && uri.hasScheme && uri.hasAuthority) {
          // URL is valid, return it
          log("StoryVideo: Extracted URL: $s", name: "StoryVideo");
          return s;
        }
        
        // If parsing failed (likely due to spaces or special chars), manually construct URI
        // Extract scheme (http or https)
        final schemeMatch = RegExp(r'^(https?://)').firstMatch(s);
        if (schemeMatch != null) {
          final scheme = schemeMatch.group(1)!.replaceAll('://', '');
          final afterScheme = s.substring(schemeMatch.end);
          
          // Extract authority (host:port) - everything up to first /
          final authorityEnd = afterScheme.indexOf('/');
          String authority;
          String? pathPart;
          
          if (authorityEnd > 0) {
            authority = afterScheme.substring(0, authorityEnd);
            // Get the rest as path, but stop at whitespace or special chars
            var remaining = afterScheme.substring(authorityEnd);
            // Remove trailing whitespace, quotes, brackets, etc.
            remaining = remaining.replaceAll(RegExp(r'[\s"\]\},]+$'), '');
            pathPart = remaining;
          } else {
            // No slash found, try to extract authority up to whitespace
            final authorityMatch = RegExp(r'^([^\s"\]\},]+)').firstMatch(afterScheme);
            authority = authorityMatch?.group(0) ?? afterScheme.split(RegExp(r'[\s"\]\},]')).first;
          }
          
          // Parse authority for host and port
          final hostPort = authority.split(':');
          final host = hostPort.first;
          final port = hostPort.length > 1 ? int.tryParse(hostPort.last) : null;
          
          // Process path if we have one
          String? path;
          if (pathPart != null && pathPart.isNotEmpty) {
            // Split path into segments and encode each segment
            final segments = pathPart.split('/')
                .where((seg) => seg.isNotEmpty)
                .map((seg) => Uri.encodeComponent(seg))
                .toList();
            if (segments.isNotEmpty) {
              path = '/${segments.join('/')}';
            }
          }
          
          // Construct the URI
          final constructedUri = Uri(
            scheme: scheme,
            host: host,
            port: port,
            path: path,
          );
          
          final finalUrl = constructedUri.toString();
          log("StoryVideo: Extracted and encoded URL: $finalUrl", name: "StoryVideo");
          return finalUrl;
        }
      } catch (e) {
        log("StoryVideo: Error parsing URL: $e", name: "StoryVideo");
      }
      
      // Fallback: simple extraction with space encoding
      final uriMatch = RegExp(r'(https?://[^\s"\]\},]+)').firstMatch(s);
      if (uriMatch != null) {
        var extracted = uriMatch.group(0)!;
        // Check if there's more content that looks like part of the URL
        final matchEnd = uriMatch.end;
        if (matchEnd < s.length) {
          final remaining = s.substring(matchEnd).trim();
          // If remaining contains file extension, it's likely part of the URL
          if (remaining.contains(RegExp(r'\.(mp4|mov|m4v|avi|webm)'))) {
            // Encode spaces and append
            extracted += remaining.replaceAll(' ', '%20');
          }
        }
        log("StoryVideo: Extracted URL (fallback): $extracted", name: "StoryVideo");
        return extracted;
      }
      
      log("StoryVideo: No regex match, using original: $s", name: "StoryVideo");
      return s;
    }

    // If stored as JSON array ["url"]
    if (s.startsWith('[') && s.endsWith(']')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List && decoded.isNotEmpty) {
          final firstItem = decoded.first;
          if (firstItem is String) {
            return _extractUrl(firstItem); // Recursively extract
          } else if (firstItem is Map) {
            // Handle map format: {"url": "https://..."}
            final url = firstItem['url']?.toString() ??
                firstItem['videoUrl']?.toString() ??
                firstItem['video_url']?.toString();
            if (url != null && url.isNotEmpty) {
              return _extractUrl(url); // Recursively extract
            }
          }
        }
      } catch (e) {
        log(
          "StoryVideo: JSON decode error: $e",
          name: "StoryVideo",
        );
      }
    }

    // If stored as JSON object {"url": "..."}
    if (s.startsWith('{') && s.endsWith('}')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) {
          final url = decoded['url']?.toString() ??
              decoded['videoUrl']?.toString() ??
              decoded['video_url']?.toString();
          if (url != null && url.isNotEmpty) {
            return _extractUrl(url); // Recursively extract
          }
        }
      } catch (e) {
        log(
          "StoryVideo: JSON object decode error: $e",
          name: "StoryVideo",
        );
      }
    }

    // Remove surrounding quotes (single or double)
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }

    // Try to extract URL using regex (handles URLs with various formats)
    // This regex matches http:// or https:// followed by valid URL characters
    // Fixed regex pattern to avoid escape issues - use character class without single quote escape
    final reg = RegExp(r'(https?://[^\s"\]\},]+)');
    final match = reg.firstMatch(s);

    if (match != null) {
      final extracted = match.group(0)!;
      // Remove any trailing invalid characters
      // Keep URL encoded as HTTP requests need encoded URLs
      return extracted.replaceAll(RegExp(r'[\]\},]+$'), '');
    }

    // If it looks like a file path or relative URL, try to construct full URL
    // (This is a fallback for edge cases)
    if (s.contains('.mp4') || s.contains('.mov') || s.contains('.m4v')) {
      // If it's already a full URL but missing scheme, add https://
      if (s.startsWith('//')) {
        return 'https:$s';
      }
    }

    log(
      "StoryVideo: Could not extract URL from: $raw",
      name: "StoryVideo",
    );
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    if (_errorText != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Video Error",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_chewieController == null || _videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Don't manually play here - let StoryProvider control playback

    // Use AspectRatio to maintain video proportions
    final aspectRatio = _videoController!.value.aspectRatio != 0
        ? _videoController!.value.aspectRatio
        : 16 / 9;

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: _chewieController != null
            ? AspectRatio(
                aspectRatio: aspectRatio,
                child: Chewie(controller: _chewieController!),
              )
            : _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
      ),
    );
  }
}
