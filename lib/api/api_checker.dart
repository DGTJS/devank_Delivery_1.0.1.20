import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/favourite/controllers/favourite_controller.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';

class ApiChecker {
  static Future<void> checkApi(Response response, {bool showToaster = false}) async {
    try {
      if (response.statusCode == 401) {
        try {
          // Limpa os dados do usuário e navega para a tela inicial
          await Get.find<AuthController>().clearSharedData(removeToken: false);
          Get.find<FavouriteController>().removeFavourites();
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } catch (error) {
          // Tratamento de erro durante a limpeza dos dados ou redirecionamento
          showCustomSnackBar('Erro ao finalizar sessão: ${error.toString()}', showToaster: true);
        }
      } else {
        // Exibe uma mensagem de erro baseada no status da resposta
        showCustomSnackBar(response.statusText ?? 'Erro desconhecido', showToaster: showToaster);
      }
    } catch (e) {
      // Tratamento de exceções inesperadas
      showCustomSnackBar('Erro inesperado: ${e.toString()}', showToaster: true);
    }
  }
}

