import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/services/network_connectivity_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

/// Widget that displays a banner when there's no internet connection
class NetworkStatusBanner extends StatefulWidget {
  const NetworkStatusBanner({super.key});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  final NetworkConnectivityService _connectivityService =
      NetworkConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppThemeData.danger300,
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "No internet connection".tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

