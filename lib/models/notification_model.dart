class NotificationModel {
  String? subject;
  String? id;
  String? type;
  String? message;
  String? createdAt;

  NotificationModel({
    this.subject,
    this.id,
    this.type,
    this.message,
    this.createdAt,
  });

  NotificationModel.fromJson(Map<String, dynamic> json) {
    subject = json['subject'];
    id = json['id'];
    type = json['type'];
    message = json['message'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['subject'] = subject;
    data['id'] = id;
    data['type'] = type;
    data['message'] = message;
    data['createdAt'] = createdAt;
    return data;
  }
}
