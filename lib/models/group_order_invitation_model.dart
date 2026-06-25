class GroupOrderInvitationModel {
  final int groupOrdersInvitationId;
  final int hostCustomerId;
  final int outletId;
  final String invitationCode;
  final String status;
  final int orderCloseDurationInMinutes;
  final String paymentResponsibility;
  final int maxMembers;
  final String? createdAt;
  final int createdBy;

  GroupOrderInvitationModel({
    required this.groupOrdersInvitationId,
    required this.hostCustomerId,
    required this.outletId,
    required this.invitationCode,
    required this.status,
    required this.orderCloseDurationInMinutes,
    required this.paymentResponsibility,
    required this.maxMembers,
    this.createdAt,
    required this.createdBy,
  });

  factory GroupOrderInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupOrderInvitationModel(
      groupOrdersInvitationId:
          (json['groupOrdersInvitationId'] as num?)?.toInt() ?? 0,
      hostCustomerId: (json['hostCustomerId'] as num?)?.toInt() ?? 0,
      outletId: (json['outletId'] as num?)?.toInt() ?? 0,
      invitationCode: json['invitationCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      orderCloseDurationInMinutes:
          (json['orderCloseDurationInMinutes'] as num?)?.toInt() ?? 0,
      paymentResponsibility:
          json['paymentResponsibility']?.toString() ?? '',
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString(),
      createdBy: (json['createdBy'] as num?)?.toInt() ?? 0,
    );
  }
}
