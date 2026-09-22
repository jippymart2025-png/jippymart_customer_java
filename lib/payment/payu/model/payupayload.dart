class PayUPayload {
  final String key;
  final String txnid;
  final String amount;
  final String productinfo;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final String surl;
  final String furl;
  final String hash;

  final String udf1;
  final String udf2;
  final String udf3;
  final String udf4;
  final String udf5;

  PayUPayload({
    required this.key,
    required this.txnid,
    required this.amount,
    required this.productinfo,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.surl,
    required this.furl,
    required this.hash,
    required this.udf1,
    required this.udf2,
    required this.udf3,
    required this.udf4,
    required this.udf5,
  });

  factory PayUPayload.fromJson(Map<String, dynamic> json) {
    return PayUPayload(
      key: json["key"],
      txnid: json["txnid"],
      amount: json["amount"],
      productinfo: json["productinfo"],
      firstname: json["firstname"],
      lastname: json["lastname"] ?? "",
      email: json["email"],
      phone: json["phone"],
      surl: json["surl"],
      furl: json["furl"],
      hash: json["hash"],
      udf1: json["udf1"] ?? "",
      udf2: json["udf2"] ?? "",
      udf3: json["udf3"] ?? "",
      udf4: json["udf4"] ?? "",
      udf5: json["udf5"] ?? "",
    );
  }

  Map<String, String> toFormData() {
    return {
      "key": key,
      "txnid": txnid,
      "amount": amount,
      "productinfo": productinfo,
      "firstname": firstname,
      "lastname": lastname,
      "email": email,
      "phone": phone,
      "surl": surl,
      "furl": furl,
      "hash": hash,
      "udf1": udf1,
      "udf2": udf2,
      "udf3": udf3,
      "udf4": udf4,
      "udf5": udf5,
    };
  }
}
