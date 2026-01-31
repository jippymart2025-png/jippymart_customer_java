import 'dart:convert';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TermsAndConditionScreen extends StatefulWidget {
  final String? type;

  const TermsAndConditionScreen({super.key, this.type});

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  String _content = '';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      // First, try to get from Constant
      String content = widget.type == "privacy"
          ? Constant.privacyPolicy
          : Constant.termsAndConditions;

      if (kDebugMode) {
        print('[TERMS] Screen type: ${widget.type}');
        print('[TERMS] Content from Constant length: ${content.length}');
      }

      // If content is empty, fetch directly from API
      if (content.isEmpty) {
        if (kDebugMode) {
          print('[TERMS] Content empty, fetching from API...');
        }
        content = await _fetchContentFromApi();
      }

      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print('[TERMS] Final content length: ${_content.length}');
        if (_content.isNotEmpty) {
          print(
            '[TERMS] Content preview: ${_content.substring(0, _content.length > 100 ? 100 : _content.length)}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TERMS] Error loading content: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _fetchContentFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}settings/mobile'),
        headers: await getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, dynamic> documents = data['data']['documents'];

          String content = '';
          if (widget.type == "privacy") {
            // Try different possible field names
            content = documents['privacyPolicy']?['privacy_policy'] ??
                documents['privacyPolicy']?['privacyPolicy'] ??
                documents['privacy_policy']?['privacy_policy'] ??
                documents['privacy_policy']?['privacyPolicy'] ??
                '';

            if (kDebugMode && content.isEmpty) {
              print(
                '[TERMS] Privacy Policy field not found. Available fields: ${documents['privacyPolicy']?.keys}',
              );
            }
          } else {
            // Try different possible field names
            content = documents['termsAndConditions']?['termsAndConditions'] ??
                documents['termsAndConditions']?['terms_and_conditions'] ??
                documents['terms_and_conditions']?['termsAndConditions'] ??
                documents['terms_and_conditions']?['terms_and_conditions'] ??
                '';

            if (kDebugMode && content.isEmpty) {
              print(
                '[TERMS] Terms & Conditions field not found. Available fields: ${documents['termsAndConditions']?.keys}',
              );
            }
          }

          // Update Constant for future use
          if (widget.type == "privacy") {
            Constant.privacyPolicy = content;
          } else {
            Constant.termsAndConditions = content;
          }

          return content;
        }
      }

      if (kDebugMode) {
        print('[TERMS] API request failed: ${response.statusCode}');
      }
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('[TERMS] Error fetching from API: $e');
      }
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.grey50,
      appBar: AppBar(
        backgroundColor: AppThemeData.grey50,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: Icon(Icons.chevron_left_outlined, color: AppThemeData.grey900),
        ),
        title: Text(
          widget.type == "privacy"
              ? "Privacy Policy".tr
              : "Terms & Conditions".tr,
          style: TextStyle(
            color: AppThemeData.grey800,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: AppThemeData.grey200, height: 4.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? _buildErrorWidget()
                  : _content.isEmpty
                      ? _buildEmptyWidget()
                      : SingleChildScrollView(
                          child: Html(
                            shrinkWrap: true,
                            data: _content,
                            style: {
                              "body": Style(
                                fontSize: FontSize(14),
                                color: AppThemeData.grey800,
                                fontFamily: AppThemeData.regular,
                              ),
                              "p": Style(
                                fontSize: FontSize(14),
                                color: AppThemeData.grey800,
                                margin: Margins.only(bottom: 12),
                              ),
                              "h1": Style(
                                fontSize: FontSize(20),
                                fontWeight: FontWeight.bold,
                                color: AppThemeData.grey900,
                                margin: Margins.only(top: 16, bottom: 12),
                              ),
                              "h2": Style(
                                fontSize: FontSize(18),
                                fontWeight: FontWeight.bold,
                                color: AppThemeData.grey900,
                                margin: Margins.only(top: 14, bottom: 10),
                              ),
                              "h3": Style(
                                fontSize: FontSize(16),
                                fontWeight: FontWeight.w600,
                                color: AppThemeData.grey900,
                                margin: Margins.only(top: 12, bottom: 8),
                              ),
                              "li": Style(
                                fontSize: FontSize(14),
                                color: AppThemeData.grey800,
                                margin: Margins.only(bottom: 6),
                              ),
                              "ul": Style(
                                margin: Margins.only(left: 10, bottom: 12),
                              ),
                              "ol": Style(
                                margin: Margins.only(left: 10, bottom: 12),
                              ),
                            },
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppThemeData.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            widget.type == "privacy"
                ? "Privacy Policy not available".tr
                : "Terms & Conditions not available".tr,
            style: TextStyle(
              fontSize: 16,
              color: AppThemeData.grey600,
              fontFamily: AppThemeData.medium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Please contact support for more information.".tr,
            style: TextStyle(
              fontSize: 14,
              color: AppThemeData.grey500,
              fontFamily: AppThemeData.regular,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppThemeData.danger300,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load content".tr,
            style: TextStyle(
              fontSize: 16,
              color: AppThemeData.grey600,
              fontFamily: AppThemeData.medium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _loadContent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary300,
            ),
            child: Text(
              "Retry".tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
