class GroupOrderJoinResponse {
  final String statusCode;
  final String statusMsg;
  final bool success;

  GroupOrderJoinResponse({
    required this.statusCode,
    required this.statusMsg,
    required this.success,
  });

  factory GroupOrderJoinResponse.fromJson(Map<String, dynamic> json) {
    final statusCode = json['statusCode']?.toString() ?? '';
    final statusMsg = json['statusMsg']?.toString() ?? '';
    final httpSuccess = statusCode == '200' || statusCode == '201';
    return GroupOrderJoinResponse(
      statusCode: statusCode,
      statusMsg: statusMsg,
      success: httpSuccess || json['success'] == true,
    );
  }
}
