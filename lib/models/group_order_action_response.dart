class GroupOrderActionResponse {
  final String statusCode;
  final String statusMsg;
  final bool success;

  GroupOrderActionResponse({
    required this.statusCode,
    required this.statusMsg,
    required this.success,
  });

  factory GroupOrderActionResponse.fromJson(Map<String, dynamic> json) {
    final statusCode = json['statusCode']?.toString() ?? '';
    final statusMsg = json['statusMsg']?.toString() ?? '';
    final httpSuccess = statusCode == '200' || statusCode == '201';
    return GroupOrderActionResponse(
      statusCode: statusCode,
      statusMsg: statusMsg,
      success: httpSuccess || json['success'] == true,
    );
  }
}
