import 'package:cached_network_image/cached_network_image.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/performance_optimizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:async';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;
  final bool fixOrientation;

  const NetworkImageWidget({
    super.key,
    this.height,
    this.width,
    this.fit,
    required this.imageUrl,
    this.borderRadius,
    this.color,
    this.errorWidget,
    this.fixOrientation = false,
  });

  /// Static helper method to get placeholder image widget
  /// Handles both asset paths and network URLs for Constant.placeholderImage
  static Widget getPlaceholderImage({
    required BuildContext context,
    double? height,
    double? width,
    BoxFit? fit,
  }) {
    final placeholder = Constant.placeholderImage;

    // Check if placeholder is empty or null
    if (placeholder.isEmpty ||
        placeholder == "null" ||
        placeholder == "Null" ||
        placeholder == "NULL") {
      // Use default asset if placeholder is invalid
      return Image.asset(
        "assets/images/food_delivery.jpeg",
        fit: fit ?? BoxFit.fitWidth,
        height: height ?? Responsive.height(8, context),
        width: width ?? Responsive.width(15, context),
      );
    }

    // Check if placeholder is a network URL
    final isNetworkUrl =
        placeholder.startsWith('http://') ||
        placeholder.startsWith('https://') ||
        placeholder.contains('firebasestorage') ||
        placeholder.contains('://');

    if (isNetworkUrl) {
      // Use Image.network for URLs
      return Image.network(
        placeholder,
        fit: fit ?? BoxFit.fitWidth,
        height: height ?? Responsive.height(8, context),
        width: width ?? Responsive.width(15, context),
        errorBuilder: (ctx, error, stackTrace) {
          // Fallback to default asset if network image fails
          return Image.asset(
            "assets/images/food_delivery.jpeg",
            fit: fit ?? BoxFit.fitWidth,
            height: height ?? Responsive.height(8, ctx),
            width: width ?? Responsive.width(15, ctx),
          );
        },
      );
    } else {
      // Check if the path looks like an asset path (contains assets/)
      if (placeholder.contains('assets/') || placeholder.contains('images/')) {
        // Use Image.asset for asset paths
        return Image.asset(
          placeholder,
          fit: fit ?? BoxFit.fitWidth,
          height: height ?? Responsive.height(8, context),
          width: width ?? Responsive.width(15, context),
          errorBuilder: (ctx, error, stackTrace) {
            // Fallback to default asset if specified asset fails
            return Image.asset(
              "assets/images/food_delivery.jpeg",
              fit: fit ?? BoxFit.fitWidth,
              height: height ?? Responsive.height(8, ctx),
              width: width ?? Responsive.width(15, ctx),
            );
          },
        );
      } else {
        // If it's not clearly a network URL and not an asset path,
        // assume it's an asset and try loading it
        try {
          return Image.asset(
            placeholder,
            fit: fit ?? BoxFit.fitWidth,
            height: height ?? Responsive.height(8, context),
            width: width ?? Responsive.width(15, context),
          );
        } catch (e) {
          // Fallback to default asset
          return Image.asset(
            "assets/images/food_delivery.jpeg",
            fit: fit ?? BoxFit.fitWidth,
            height: height ?? Responsive.height(8, context),
            width: width ?? Responsive.width(15, context),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle null, empty, or invalid URLs
    if (imageUrl.isEmpty ||
        imageUrl == "null" ||
        imageUrl == "Null" ||
        imageUrl == "NULL" ||
        imageUrl == "[]" ||
        imageUrl == "[" ||
        imageUrl == "]" ||
        imageUrl.startsWith("[") && imageUrl.endsWith("]")) {
      return errorWidget ??
          NetworkImageWidget.getPlaceholderImage(
            context: context,
            height: height,
            width: width,
            fit: fit,
          );
    }

    // Validate URL format to prevent FormatException
    String cleanImageUrl = imageUrl.trim();

    // Remove any extra quotes that might be causing issues
    if (cleanImageUrl.startsWith('"') && cleanImageUrl.endsWith('"')) {
      cleanImageUrl = cleanImageUrl.substring(1, cleanImageUrl.length - 1);
    }
    if (cleanImageUrl.startsWith("'") && cleanImageUrl.endsWith("'")) {
      cleanImageUrl = cleanImageUrl.substring(1, cleanImageUrl.length - 1);
    }

    // Handle URLs with spaces - encode them properly
    if (cleanImageUrl.contains(' ')) {
      try {
        final uri = Uri.parse(cleanImageUrl);
        // Re-encode the path segments to handle spaces
        cleanImageUrl = uri.replace(
          pathSegments: uri.pathSegments.map((s) => Uri.encodeComponent(s)).toList(),
        ).toString();
      } catch (e) {
        // If parsing fails, try simple space replacement
        cleanImageUrl = cleanImageUrl.replaceAll(' ', '%20');
      }
    }

    // Check if URL is valid
    try {
      final uri = Uri.parse(cleanImageUrl);
      // Ensure the URL has a valid host
      if (uri.host.isEmpty) {
        if (kDebugMode) {
          print('[NETWORK_IMAGE] Invalid URL - no host: $imageUrl');
        }
        return errorWidget ??
            NetworkImageWidget.getPlaceholderImage(
              context: context,
              height: height,
              width: width,
              fit: fit,
            );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NETWORK_IMAGE] Invalid URL format: $imageUrl');
      }
      return errorWidget ??
          NetworkImageWidget.getPlaceholderImage(
            context: context,
            height: height,
            width: width,
            fit: fit,
          );
    }

    // Add to performance tracking for optimization
    PerformanceOptimizer.addToLazyLoadQueue(cleanImageUrl);

    // If orientation fix is requested, use the oriented version
    if (fixOrientation) {
      return _OrientedNetworkImage(
        imageUrl: cleanImageUrl,
        height: height,
        width: width,
        fit: fit,
        borderRadius: borderRadius,
        color: color,
        errorWidget: errorWidget,
      );
    }

    // Check if the image URL is AVIF format
    bool isAvifFormat = _isAvifFormat(cleanImageUrl);

    // For AVIF images, use a fallback approach since Flutter doesn't support AVIF natively
    if (isAvifFormat) {
      return _AvifFallbackImage(
        imageUrl: cleanImageUrl,
        height: height,
        width: width,
        fit: fit,
        color: color,
        errorWidget: errorWidget,
      );
    }

    return CachedNetworkImage(
      imageUrl: cleanImageUrl,
      fit: fit ?? BoxFit.fitWidth,
      height: height ?? Responsive.height(8, context),
      width: width ?? Responsive.width(15, context),
      color: color,
      // Enhanced caching configuration
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      memCacheWidth: 300,
      memCacheHeight: 300,
      // Keep images in cache longer
      cacheKey: cleanImageUrl,
      // Use URL as cache key for consistency
      useOldImageOnUrlChange: true,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          _buildLoadingWidget(),
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          print(
            '[NETWORK_IMAGE] Error loading cached image: $error for URL: $url',
          );
        }
        return errorWidget ??
            NetworkImageWidget.getPlaceholderImage(
              context: context,
              height: height,
              width: width,
              fit: fit,
            );
      },
    );
  }

  // Enhanced format detection
  bool _isAvifFormat(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.avif') ||
        lowerUrl.contains('format=avif') ||
        lowerUrl.contains('&format=avif');
  }

  // Safe loading widget that handles missing assets gracefully
  Widget _buildLoadingWidget() {
    try {
      return Image.asset(
        "assets/images/simmer_gif.gif",
        height: height,
        width: width,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('[NETWORK_IMAGE] Error loading shimmer gif: $error');
          }
          return Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[NETWORK_IMAGE] Error creating loading widget: $e');
      }
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }
}

// Make AvifFallbackImage a private class (prefixed with underscore)
class _AvifFallbackImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final Color? color;

  const _AvifFallbackImage({
    super.key,
    this.height,
    this.width,
    this.fit,
    required this.imageUrl,
    this.color,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFallbackUrl(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        // If we have a fallback URL, use it
        if (snapshot.hasData && snapshot.data != null) {
          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            fit: fit ?? BoxFit.fitWidth,
            height: height ?? Responsive.height(8, context),
            width: width ?? Responsive.width(15, context),
            color: color,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                _buildLoadingWidget(),
            errorWidget: (context, url, error) {
              if (kDebugMode) {
                print('[AVIF_FALLBACK] Error loading fallback image: $error');
              }
              return _buildErrorWidget(context);
            },
          );
        }

        // If no fallback available, show error widget
        if (kDebugMode) {
          print(
            '[AVIF_FALLBACK] No fallback URL available for AVIF image: $imageUrl',
          );
        }
        return _buildErrorWidget(context);
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return errorWidget ??
        NetworkImageWidget.getPlaceholderImage(
          context: context,
          height: height,
          width: width,
          fit: fit,
        );
  }

  // Safe loading widget that handles missing assets gracefully
  Widget _buildLoadingWidget() {
    try {
      return Image.asset(
        "assets/images/simmer_gif.gif",
        height: height,
        width: width,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('[AVIF_FALLBACK] Error loading shimmer gif: $error');
          }
          return Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AVIF_FALLBACK] Error creating loading widget: $e');
      }
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }

  Future<String?> _getFallbackUrl(String avifUrl) async {
    try {
      // Try to get a WebP or JPEG version of the same image
      String fallbackUrl = avifUrl;
      // Replace .avif with .webp
      if (fallbackUrl.toLowerCase().contains('.avif')) {
        fallbackUrl = fallbackUrl.replaceAll(
          RegExp(r'\.avif', caseSensitive: false),
          '.webp',
        );
      }

      // If URL contains format parameter, try to change it
      if (fallbackUrl.contains('format=avif')) {
        fallbackUrl = fallbackUrl.replaceAll('format=avif', 'format=webp');
      }

      // Test if the fallback URL exists with timeout
      final response = await http
          .head(Uri.parse(fallbackUrl))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException(
                'Request timeout',
                const Duration(seconds: 5),
              );
            },
          );
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('[AVIF_FALLBACK] Using WebP fallback: $fallbackUrl');
        }
        return fallbackUrl;
      }

      // Try JPEG fallback
      fallbackUrl = avifUrl;
      if (fallbackUrl.toLowerCase().contains('.avif')) {
        fallbackUrl = fallbackUrl.replaceAll(
          RegExp(r'\.avif', caseSensitive: false),
          '.jpg',
        );
      }
      if (fallbackUrl.contains('format=avif')) {
        fallbackUrl = fallbackUrl.replaceAll('format=avif', 'format=jpeg');
      }

      final jpegResponse = await http
          .head(Uri.parse(fallbackUrl))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException(
                'Request timeout',
                const Duration(seconds: 5),
              );
            },
          );
      if (jpegResponse.statusCode == 200) {
        if (kDebugMode) {
          print('[AVIF_FALLBACK] Using JPEG fallback: $fallbackUrl');
        }
        return fallbackUrl;
      }

      if (kDebugMode) {
        print('[AVIF_FALLBACK] No fallback URL found for: $avifUrl');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[AVIF_FALLBACK] Error getting fallback URL: $e');
      }
      return null;
    }
  }
}

// Make OrientedNetworkImage a private class (prefixed with underscore)
class _OrientedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;

  const _OrientedNetworkImage({
    super.key,
    this.height,
    this.width,
    this.fit,
    required this.imageUrl,
    this.borderRadius,
    this.color,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Handle null or empty URLs
    if (imageUrl.isEmpty ||
        imageUrl == "null" ||
        imageUrl == "Null" ||
        imageUrl == "NULL") {
      return errorWidget ??
          NetworkImageWidget.getPlaceholderImage(
            context: context,
            height: height,
            width: width,
            fit: fit,
          );
    }

    // Validate URL format to prevent FormatException
    String cleanImageUrl = imageUrl.trim();

    // Remove any extra quotes that might be causing issues
    if (cleanImageUrl.startsWith('"') && cleanImageUrl.endsWith('"')) {
      cleanImageUrl = cleanImageUrl.substring(1, cleanImageUrl.length - 1);
    }
    if (cleanImageUrl.startsWith("'") && cleanImageUrl.endsWith("'")) {
      cleanImageUrl = cleanImageUrl.substring(1, cleanImageUrl.length - 1);
    }

    // Check if URL is valid
    try {
      Uri.parse(cleanImageUrl);
    } catch (e) {
      if (kDebugMode) {
        print('[ORIENTED_IMAGE] Invalid URL format: $imageUrl');
      }
      return errorWidget ??
          NetworkImageWidget.getPlaceholderImage(
            context: context,
            height: height,
            width: width,
            fit: fit,
          );
    }

    return FutureBuilder<ui.Image?>(
      future: _loadImageWithOrientation(cleanImageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (snapshot.hasError || snapshot.data == null) {
          if (kDebugMode) {
            print('[ORIENTED_IMAGE] Error loading image: ${snapshot.error}');
          }
          return errorWidget ??
              NetworkImageWidget.getPlaceholderImage(
                context: context,
                height: height,
                width: width,
                fit: fit,
              );
        }

        return ClipRRect(
          borderRadius: borderRadius != null
              ? BorderRadius.circular(borderRadius!)
              : BorderRadius.zero,
          child: RawImage(
            image: snapshot.data,
            fit: fit ?? BoxFit.fitWidth,
            width: width,
            height: height,
            color: color,
          ),
        );
      },
    );
  }

  Future<ui.Image?> _loadImageWithOrientation(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(
          response.bodyBytes,
          targetWidth: width?.toInt(),
          targetHeight: height?.toInt(),
        );
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ORIENTED_IMAGE] Error loading image: $e');
      }
    }
    return null;
  }

  // Safe loading widget that handles missing assets gracefully
  Widget _buildLoadingWidget() {
    try {
      return Image.asset(
        "assets/images/simmer_gif.gif",
        height: height,
        width: width,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('[ORIENTED_IMAGE] Error loading shimmer gif: $error');
          }
          return Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[ORIENTED_IMAGE] Error creating loading widget: $e');
      }
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }
}
