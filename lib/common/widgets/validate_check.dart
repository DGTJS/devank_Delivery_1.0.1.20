
import 'package:get/get.dart';

class ValidateCheck{
  static String? validateEmail(String? value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final kEmailValid = RegExp(pattern);
    bool isValid = kEmailValid.hasMatch(value.toString());
    if (value!.isEmpty) {
      return '\u26A0 ${'email_field_is_required'.tr}';
    } else if (isValid == false) {
      return '\u26A0 ${"enter_valid_email_address".tr}';
    }
    return null;
  }
static String? validatePix(String? value) {
    
    final kEmailValid = value!.length > 3;
    if (value!.isEmpty) {
      return '\u26A0 ${'pix_field_is_required'.tr}';
    } else if (kEmailValid == false) {
      return '\u26A0 ${"enter_valid_pix".tr}';
    }
    return null;
  }
  static String? validateCpf(String? value) {
    const pattern = r"^\d{3}\.\d{3}\.\d{3}-\d{2}$";
    final kCpfValid = RegExp(pattern);
    bool isValid = kCpfValid.hasMatch(value.toString());
    //regra de validação de CPF brasil
    // Regra de validação de CPF Brasil
    int sum = 0;
    int remainder;
    if (value == "000.000.000-00" ||
      value == "111.111.111-11" ||
      value == "222.222.222-22" ||
      value == "333.333.333-33" ||
      value == "444.444.444-44" ||
      value == "555.555.555-55" ||
      value == "666.666.666-66" ||
      value == "777.777.777-77" ||
      value == "888.888.888-88" ||
      value == "999.999.999-99") {
      return '\u26A0 ${"enter_valid_cpf".tr}';
    }

    List<int> numbers = value!.replaceAll(RegExp(r'\D'), '').split('').map((e) => int.parse(e)).toList();

    for (int i = 0; i < 9; i++) {
      sum += numbers[i] * (10 - i);
    }
    remainder = 11 - (sum % 11);
    if (remainder == 10 || remainder == 11) {
      remainder = 0;
    }
    if (remainder != numbers[9]) {
      return '\u26A0 ${"enter_valid_cpf".tr}';
    }

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += numbers[i] * (11 - i);
    }
    remainder = 11 - (sum % 11);
    if (remainder == 10 || remainder == 11) {
      remainder = 0;
    }
    if (remainder != numbers[10]) {
      return '\u26A0 ${"enter_valid_cpf".tr}';
    }if (value!.isEmpty) {
      return '\u26A0 ${'cpf_field_is_required'.tr}';
    } else if (isValid == false) {
      return '\u26A0 ${"enter_valid_cpf".tr}';
    }
    return null;
  }

  static String? validateBirth(String? value) {
    const pattern = r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/(19|20)\d{2}$';
    final kBirthValid = RegExp(pattern);
    bool isValid = kBirthValid.hasMatch(value.toString());
    if (value!.isEmpty) {
      return '\u26A0 ${'birth_field_is_required'.tr}';
    } else if (isValid == false) {
      return '\u26A0 ${"enter_valid_birth".tr}';
    }
    return null;
  }

  static String? validateEmptyText(String? value, String? message) {
    if (value == null || value.isEmpty) {
      return message?.tr??'this_field_is_required'.tr;
    }
    return null;
  }

  static String? validatePhone(String? value, String? message) {
    if (value == null || value.isEmpty) {
      return message?.tr ?? 'this_field_is_required'.tr;
    }/* else {
      PhoneValid phoneValid = await CustomValidator.isPhoneValid(value);
      if(!phoneValid.isValid) {
        return message?.tr ?? 'invalid_phone_number'.tr;
      }
    }*/
    return null;
  }

  static String? validatePassword(String? value, String? message) {
    if (value == null || value.isEmpty) {
      return message?.tr??'this_field_is_required'.tr;
    }else if(value.length < 8){
      return 'minimum_password_is_8_character'.tr;
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'confirm_password_field_is_required'.tr;
    }else if(value != password){
      return 'confirm_password_does_not_matched'.tr;
    }
    return null;
  }

  static String? loyaltyCheck(String? value, int? minimumExchangePoint, int? point) {
    int amount = 0;
    if(value != null && value.isNotEmpty) {
      amount = int.parse(value);
    }
    if (value == null || value.isEmpty) {
      return 'this_field_is_required'.tr;
    }else if(amount < minimumExchangePoint!){
      return '${'please_exchange_more_then'.tr} $minimumExchangePoint ${'points'.tr}';
    }else if(point! < amount){
      return 'you_do_not_have_enough_point_to_exchange'.tr;
    }
    return null;
  }
}