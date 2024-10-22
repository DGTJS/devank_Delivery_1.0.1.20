class SignUpBodyModel {
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? refCode;
  String? cpf;
  String? birth;

  SignUpBodyModel({this.fName, this.lName, this.phone, this.email='', this.password, this.refCode = '', this.cpf = '', this.birth = '' });

  SignUpBodyModel.fromJson(Map<String, dynamic> json) {
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    password = json['password'];
    refCode = json['ref_code'];
    birth = json['birth'];
    cpf = json['cpf'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['email'] = email;
    data['password'] = password;
    data['ref_code'] = refCode;
    data['birth'] = birth;
    data['cpf'] = cpf;
    return data;
  }
}
