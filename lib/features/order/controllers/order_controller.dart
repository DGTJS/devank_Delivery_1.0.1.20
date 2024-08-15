import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stackfood_multivendor/common/models/product_model.dart';
import 'package:stackfood_multivendor/common/models/response_model.dart';
import 'package:stackfood_multivendor/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/cart/controllers/cart_controller.dart';
import 'package:stackfood_multivendor/features/cart/domain/models/cart_model.dart';
import 'package:stackfood_multivendor/features/checkout/domain/models/place_order_body_model.dart';
import 'package:stackfood_multivendor/features/loyalty/controllers/loyalty_controller.dart';
import 'package:stackfood_multivendor/features/order/domain/models/delivery_log_model.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_cancellation_body.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_details_model.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor/features/order/domain/models/pause_log_model.dart';
import 'package:stackfood_multivendor/features/order/domain/models/subscription_schedule_model.dart';
import 'package:stackfood_multivendor/features/order/domain/services/order_service_interface.dart';
import 'package:stackfood_multivendor/helper/address_helper.dart';
import 'package:stackfood_multivendor/helper/auth_helper.dart';
import 'package:stackfood_multivendor/helper/date_converter.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;

  OrderController({required this.orderServiceInterface});

  List<int> _runningOffsetList = [];
  List<int> _runningSubscriptionOffsetList = [];
  List<int> _historyOffsetList = [];

  int _runningOffset = 1;
  int get runningOffset => _runningOffset;

  List<OrderModel>? _runningOrderList;
  List<OrderModel>? get runningOrderList => _runningOrderList;

  List<OrderModel>? _runningSubscriptionOrderList;
  List<OrderModel>? get runningSubscriptionOrderList =>
      _runningSubscriptionOrderList;

  List<OrderModel>? _historyOrderList;
  List<OrderModel>? get historyOrderList => _historyOrderList;

  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  int? _runningPageSize;
  int? get runningPageSize => _runningPageSize;

  bool _runningPaginate = false;
  bool get runningPaginate => _runningPaginate;

  int _runningSubscriptionOffset = 1;
  int get runningSubscriptionOffset => _runningSubscriptionOffset;

  int? _runningSubscriptionPageSize;
  int? get runningSubscriptionPageSize => _runningSubscriptionPageSize;

  bool _runningSubscriptionPaginate = false;
  bool get runningSubscriptionPaginate => _runningSubscriptionPaginate;

  int _historyOffset = 1;
  int get historyOffset => _historyOffset;

  int? _historyPageSize;
  int? get historyPageSize => _historyPageSize;

  bool _historyPaginate = false;
  bool get historyPaginate => _historyPaginate;

  Timer? _timer;

  bool _showCancelled = false;
  bool get showCancelled => _showCancelled;

  OrderModel? _trackModel;
  OrderModel? get trackModel => _trackModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CancellationData>? _orderCancelReasons;
  List<CancellationData>? get orderCancelReasons => _orderCancelReasons;

  List<SubscriptionScheduleModel>? _schedules;
  List<SubscriptionScheduleModel>? get schedules => _schedules;

  PaginatedDeliveryLogModel? _deliverLogs;
  PaginatedDeliveryLogModel? get deliveryLogs => _deliverLogs;

  PaginatedPauseLogModel? _pauseLogs;
  PaginatedPauseLogModel? get pauseLogs => _pauseLogs;

  bool _subscriveLoading = false;
  bool get subscriveLoading => _subscriveLoading;

  String? _cancelReason;
  String? get cancelReason => _cancelReason;

  bool _canReorder = true;
  String _reorderMessage = '';

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  int _selectedReasonIndex = 0;
  int get selectedReasonIndex => _selectedReasonIndex;

  List<String?>? _refundReasons;
  List<String?>? get refundReasons => _refundReasons;

  XFile? _refundImage;
  XFile? get refundImage => _refundImage;

  int? _cancellationIndex = 0;
  int? get cancellationIndex => _cancellationIndex;

  bool _showBottomSheet = true;
  bool get showBottomSheet => _showBottomSheet;

  bool _showOneOrder = true;
  bool get showOneOrder => _showOneOrder;

  bool _isCancelLoading = false;
  bool get isCancelLoading => _isCancelLoading;

  final StreamController<OrderModel> _deliveryLocationController =
      StreamController<OrderModel>.broadcast();
  // Stream de localização do entregador
  Stream<OrderModel> get deliveryLocationStream =>
      _deliveryLocationController.stream;
  // Controle para o mapa do Google
  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;
  // Localização do entregador (inicialmente nula)
  final Rx<LatLng?> deliveryLocation = Rx<LatLng?>(null);

  // Função para parar o rastreamento
  void stopTrackingDeliveryLocation() {
    _timer?.cancel();
    _deliveryLocationController.close();
  }

  Future<void> getRunningOrders(int offset,
      {bool notify = true, int limit = 100}) async {
    print('PASSOU NO GET RUNNING ORDERS');
    if (offset == 1) {
      _runningOffsetList = [];
      _runningOffset = 1;
      _runningOrderList = null;
      if (notify) {
        update();
      }
    }
    if (!_runningOffsetList.contains(offset)) {
      _runningOffsetList.add(offset);
      PaginatedOrderModel? paginatedOrderModel =
          await orderServiceInterface.getRunningOrderList(offset,
              AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(), limit);
      if (paginatedOrderModel != null) {
        if (offset == 1) {
          _runningOrderList = [];
        }
        _runningOrderList!.addAll(paginatedOrderModel.orders!);
        _runningPageSize = paginatedOrderModel.totalSize;
        _runningPaginate = false;

        update();
      }
    } else {
      if (_runningPaginate) {
        _runningPaginate = false;
        update();
      }
    }
  }

  Future<void> getRunningSubscriptionOrders(int offset,
      {bool notify = true}) async {
    print('PASSOU NO RUNNING SUBS');
    if (offset == 1) {
      _runningSubscriptionOffsetList = [];
      _runningSubscriptionOffset = 1;
      _runningSubscriptionOrderList = null;
      if (notify) {
        update();
      }
    }
    if (!_runningSubscriptionOffsetList.contains(offset)) {
      _runningSubscriptionOffsetList.add(offset);
      PaginatedOrderModel? paginatedOrderModel =
          await orderServiceInterface.getRunningSubscriptionOrderList(offset);
      if (paginatedOrderModel != null) {
        if (offset == 1) {
          _runningSubscriptionOrderList = [];
        }
        _runningSubscriptionOrderList!.addAll(paginatedOrderModel.orders!);
        _runningSubscriptionPageSize = paginatedOrderModel.totalSize;
        _runningSubscriptionPaginate = false;
        update();
      }
    } else {
      if (_runningSubscriptionPaginate) {
        _runningSubscriptionPaginate = false;
        update();
      }
    }
  }

  Future<void> getHistoryOrders(int offset, {bool notify = true}) async {
    if (offset == 1) {
      _historyOffsetList = [];
      _historyOrderList = null;
      if (notify) {
        update();
      }
    }
    _historyOffset = offset;
    if (!_historyOffsetList.contains(offset)) {
      _historyOffsetList.add(offset);
      PaginatedOrderModel? paginatedOrderModel =
          await orderServiceInterface.getHistoryOrderList(offset);
      if (paginatedOrderModel != null) {
        if (offset == 1) {
          _historyOrderList = [];
        }
        _historyOrderList!.addAll(paginatedOrderModel.orders!);
        _historyPageSize = paginatedOrderModel.totalSize;
        _historyPaginate = false;
        update();
      }
    } else {
      if (_historyPaginate) {
        _historyPaginate = false;
        update();
      }
    }
  }

  void setOffset(int offset, bool isRunning, bool isSubscription) {
    if (isRunning) {
      _runningOffset = offset;
    } else if (isSubscription) {
      _runningSubscriptionOffset = offset;
    } else {
      _historyOffset = offset;
    }
  }

  void showBottomLoader(bool isRunning, bool isSubscription) {
    if (isRunning) {
      _runningPaginate = true;
    } else if (isSubscription) {
      _runningSubscriptionPaginate = true;
    } else {
      _historyPaginate = true;
    }
    update();
  }

  void callTrackOrderApi(
      {required OrderModel orderModel,
      required String orderId,
      String? contactNumber}) {
    // Verifica se o pedido não está em um dos estados finais
    if (orderModel.orderStatus != 'delivered' &&
        orderModel.orderStatus != 'failed' &&
        orderModel.orderStatus != 'canceled') {
      // Cancela o temporizador existente, se houver
      _timer?.cancel();
      // Configura um novo temporizador para rastrear o pedido periodicamente
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (_isTrackingRoute()) {
        await timerTrackOrder(orderId.toString(), contactNumber: contactNumber);
        startTracking(orderId, contactNumber);
        } else {
          _timer?.cancel();
        }
      });
    } else {
      // Chama a função de rastreamento do pedido independentemente do status
      timerTrackOrder(orderId, contactNumber: contactNumber);
    }
  }

  // Função auxiliar para iniciar o rastreamento do pedido
  void startTracking(String orderId, String? contactNumber) async {
    final updatedOrderModel = await orderServiceInterface.trackOrder(
      orderId,
      AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
      contactNumber: contactNumber,
    );
    _deliveryLocationController.sink.add(updatedOrderModel!);
  }

  /// Função auxiliar para verificar se a rota atual é de rastreamento.
  ///
  /// Retorna `true` se a rota atual for uma das rotas de detalhes do pedido ou rastreamento do pedido.
  /// Caso contrário, retorna `false`.
  bool _isTrackingRoute() {
    final currentRoute = Get.currentRoute;
    return currentRoute != null &&
        (currentRoute.contains(RouteHelper.orderDetails) ||
            currentRoute.contains(RouteHelper.orderTracking));
  }

  /// Rastreia um pedido e atualiza o estado com as informações do pedido.
  ///
  /// Faz uma chamada para o serviço de rastreamento de pedidos e atualiza o modelo de rastreamento.
  /// Retorna `true` se o pedido for rastreado com sucesso, `false` caso contrário.
  ///
  /// [orderID]: O ID do pedido a ser rastreado.
  /// [contactNumber]: Um número de contato opcional para o rastreamento.
  Future<bool> timerTrackOrder(String orderID, {String? contactNumber}) async {
    _showCancelled = false;

    try {
      // Faz a chamada ao serviço de rastreamento de pedidos
      OrderModel? orderModel = await orderServiceInterface.trackOrder(
        orderID,
        AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
        contactNumber: contactNumber,
      );

      if (orderModel != null) {
        // Atualiza o modelo de rastreamento
        _trackModel = orderModel;
      }

      // Atualiza a interface do usuário
      update();

      // Retorna `true` se o pedido foi rastreado com sucesso
      return (orderModel != null);
    } catch (e) {
      // Lida com possíveis exceções
      print('Erro ao rastrear o pedido: $e');
      // Atualiza a interface do usuário mesmo em caso de erro
      update();
      return false;
    }
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  /// Rastreia um pedido e retorna um [ResponseModel] indicando o sucesso ou falha da operação.
  ///
  /// Se [orderModel] for nulo, busca as informações do pedido usando o [orderID].
  /// Se [orderModel] for fornecido, usa o modelo fornecido diretamente.
  ///
  /// [orderID]: O ID do pedido a ser rastreado, se [orderModel] for nulo.
  /// [orderModel]: O modelo do pedido a ser rastreado, se disponível.
  /// [fromTracking]: Indica se a função está sendo chamada a partir da página de rastreamento.
  /// [contactNumber]: Um número de contato opcional para o rastreamento.
  /// [fromGuestInput]: Indica se a entrada é de um convidado (opcional).
  Future<ResponseModel> trackOrder(
    String? orderID,
    OrderModel? orderModel,
    bool fromTracking, {
    String? contactNumber,
    bool? fromGuestInput = false,
  }) async {
    print('PASSOU NO TRACK ORDER ======================================');

    // Reseta o modelo de rastreamento e detalhes do pedido, se necessário
    _trackModel = null;
    if (!fromTracking) {
      _orderDetails = null;
    }

    _showCancelled = false;
    _isLoading = true; // Inicia o indicador de carregamento

    ResponseModel responseModel;

    try {
      // Se orderModel for nulo, busca as informações do pedido
      if (orderModel == null) {
        OrderModel? responseOrderModel = await orderServiceInterface.trackOrder(
          orderID,
          AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
          contactNumber: contactNumber,
        );

        // Verifica se a resposta do pedido não é nula
        if (responseOrderModel != null) {
          _trackModel = responseOrderModel;
          responseModel = ResponseModel(true, 'Successful');
        } else {
          responseModel = ResponseModel(false, 'Failed to fetch order details');
        }
      } else {
        // Usa o orderModel fornecido
        _trackModel = orderModel;
        responseModel = ResponseModel(true, 'Successful');
      }
    } catch (e) {
      // Trata exceções e define o modelo de resposta como falhado
      responseModel = ResponseModel(false, 'Error: ${e.toString()}');
    } finally {
      _isLoading = false; // Finaliza o indicador de carregamento
      update(); // Atualiza a interface do usuário
    }

    return responseModel;
  }

  /// Busca os logs de entrega para uma assinatura específica e atualiza a lista de logs.
  ///
  /// [subscriptionID]: O ID da assinatura para a qual os logs de entrega serão buscados.
  /// [offset]: O offset para a paginação dos resultados.
  Future<void> getDeliveryLogs(int? subscriptionID, int offset) async {
    // Reseta os logs se for a primeira página
    if (offset == 1) {
      _deliverLogs = null;
    }

    try {
      // Busca os logs de entrega
      PaginatedDeliveryLogModel? deliveryLogModel = await orderServiceInterface
          .getSubscriptionDeliveryLog(subscriptionID, offset);

      if (deliveryLogModel != null) {
        if (offset == 1) {
          // Inicializa a lista de logs com o novo modelo de dados
          _deliverLogs = deliveryLogModel;
        } else {
          // Adiciona os novos dados à lista existente
          if (_deliverLogs?.data != null && deliveryLogModel.data != null) {
            _deliverLogs!.data!.addAll(deliveryLogModel.data!);
          }
          _deliverLogs?.offset = deliveryLogModel.offset;
          _deliverLogs?.totalSize = deliveryLogModel.totalSize;
        }
        // Atualiza a interface do usuário
        update();
      }
    } catch (e) {
      // Trata exceções
      print('Erro ao buscar logs de entrega: $e');
      // Pode adicionar lógica de tratamento de erro se necessário
    }
  }

  Future<void> getPauseLogs(int? subscriptionID, int offset) async {
    if (offset == 1) {
      _pauseLogs = null;
    }
    PaginatedPauseLogModel? pauseLogModel = await orderServiceInterface
        .getSubscriptionPauseLog(subscriptionID, offset);
    if (pauseLogModel != null) {
      if (offset == 1) {
        _pauseLogs = pauseLogModel;
      } else {
        _pauseLogs!.data!.addAll(pauseLogModel.data!);
        _pauseLogs!.offset = pauseLogModel.offset;
        _pauseLogs!.totalSize = pauseLogModel.totalSize;
      }
      update();
    }
  }

  void setCancelIndex(int? index) {
    _cancellationIndex = index;
    update();
  }

  Future<bool> updateSubscriptionStatus(
      int? subscriptionID,
      DateTime? startDate,
      DateTime? endDate,
      String status,
      String note,
      String? reason) async {
    _subscriveLoading = true;
    update();

    ResponseModel responseModel =
        await orderServiceInterface.updateSubscriptionStatus(
      subscriptionID,
      startDate != null ? DateConverter.dateToDateAndTime(startDate) : null,
      endDate != null ? DateConverter.dateToDateAndTime(endDate) : null,
      status,
      note,
      reason,
    );
    if (responseModel.isSuccess) {
      Get.back();
      if (status == 'canceled' ||
          startDate!.isAtSameMomentAs(DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
        _trackModel!.subscription!.status = status;
      }
      showCustomSnackBar(
        status == 'paused'
            ? 'subscription_paused_successfully'.tr
            : 'subscription_cancelled_successfully'.tr,
        isError: false,
      );
    }
    _subscriveLoading = false;
    update();
    return responseModel.isSuccess;
  }

  Future<void> getOrderCancelReasons() async {
    List<CancellationData>? reasons =
        await orderServiceInterface.getCancelReasons();
    if (reasons != null) {
      _orderCancelReasons = [];
      _orderCancelReasons!.addAll(reasons);
    }
    update();
  }

  /// Busca os detalhes de um pedido específico e atualiza o estado com as informações recebidas.
  ///
  /// [orderID]: O ID do pedido cujos detalhes serão buscados.
  ///
  /// Retorna uma lista de [OrderDetailsModel] contendo os detalhes do pedido, ou `null` em caso de falha.
  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID) async {
    _isLoading = true; // Inicia o indicador de carregamento
    _showCancelled = false;

    try {
      // Faz a chamada para obter detalhes do pedido
      Response response = await orderServiceInterface.getOrderDetails(
        orderID,
        AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
      );

      if (response.statusCode == 200) {
        // Processa a resposta se o status code for 200 (OK)
        _orderDetails = orderServiceInterface.processOrderDetails(response);
        _schedules = orderServiceInterface.processSchedules(response);
      } else {
        // Lida com respostas não OK (status code diferente de 200)
        print('Erro: Status code ${response.statusCode}');
        _orderDetails = null;
      }
    } catch (e) {
      // Trata exceções que possam ocorrer durante a chamada ou processamento
      print('Erro ao buscar detalhes do pedido: $e');
      _orderDetails = null;
    } finally {
      _isLoading = false; // Finaliza o indicador de carregamento
      update(); // Atualiza a interface do usuário
    }

    return _orderDetails;
  }

  Future<bool> switchToCOD(String? orderID, String? contactNumber,
      {double? points}) async {
    _isLoading = true;
    update();
    ResponseModel responseModel =
        await orderServiceInterface.switchToCOD(orderID);
    if (responseModel.isSuccess) {
      if (points != null) {
        Get.find<LoyaltyController>()
            .saveEarningPoint(points.toStringAsFixed(0));
      }
      if (Get.find<AuthController>().isGuestLoggedIn()) {
        Get.offNamed(RouteHelper.getOrderSuccessRoute(
            orderID!, 'success', 0, contactNumber));
      } else {
        await Get.offAllNamed(RouteHelper.getInitialRoute());
      }
      showCustomSnackBar(responseModel.message, isError: false);
    }
    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }

  void selectReason(int index, {bool isUpdate = true}) {
    _selectedReasonIndex = index;
    if (isUpdate) {
      update();
    }
  }

  void setOrderCancelReason(String? reason) {
    _cancelReason = reason;
    update();
  }

  void expandedUpdate(bool status) {
    _isExpanded = status;
    update();
  }

  Future<void> getRefundReasons() async {
    _refundReasons = null;
    _refundReasons = await orderServiceInterface.getRefundReasons();
    update();
  }

  void pickRefundImage(bool isRemove) async {
    if (isRemove) {
      _refundImage = null;
    } else {
      _refundImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      update();
    }
  }

  void showRunningOrders() {
    _showBottomSheet = !_showBottomSheet;
    update();
  }

  void showOrders() {
    _showOneOrder = !_showOneOrder;
    update();
  }

  Future<void> submitRefundRequest(String note, String? orderId) async {
    if (_selectedReasonIndex == 0) {
      showCustomSnackBar('please_select_reason'.tr);
    } else {
      _isLoading = true;
      update();
      Map<String, String> body = orderServiceInterface.prepareReasonData(
          note, orderId, _refundReasons![selectedReasonIndex]!);

      ResponseModel responseModel =
          await orderServiceInterface.submitRefundRequest(body, _refundImage,
              AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
      if (responseModel.isSuccess) {
        showCustomSnackBar(responseModel.message, isError: false);
        Get.offAllNamed(RouteHelper.getInitialRoute());
      }
      _isLoading = false;
      update();
    }
  }

  Future<bool> cancelOrder(int? orderID, String? cancelReason) async {
    _isCancelLoading = true;
    update();
    ResponseModel responseModel = await orderServiceInterface.cancelOrder(
        orderID.toString(), cancelReason);
    _isCancelLoading = false;
    Get.back();
    if (responseModel.isSuccess) {
      OrderModel? orderModel =
          orderServiceInterface.findOrder(_runningOrderList, orderID);
      _runningOrderList!.remove(orderModel);
      _showCancelled = true;
      showCustomSnackBar(responseModel.message, isError: false);
    }
    update();
    return responseModel.isSuccess;
  }

  Future<void> reOrder(
      List<OrderDetailsModel> orderedFoods, int? restaurantZoneId) async {
    _isLoading = true;
    update();

    List<int?> foodIds = orderServiceInterface.prepareFoodIds(orderedFoods);
    List<Product>? responseFoods =
        await orderServiceInterface.getFoodsFromFoodIds(foodIds);
    if (responseFoods != null) {
      _canReorder = true;
      List<Product> foods = responseFoods;

      List<OnlineCart> onlineCartList = orderServiceInterface
          .prepareOnlineCartList(restaurantZoneId, orderedFoods, foods);
      List<CartModel> offlineCartList = orderServiceInterface
          .prepareOfflineCartList(restaurantZoneId, orderedFoods, foods);

      _canReorder = AddressHelper.getAddressFromSharedPref()!
          .zoneIds!
          .contains(restaurantZoneId);
      _reorderMessage = !_canReorder ? 'you_are_not_in_the_order_zone' : '';

      if (_canReorder) {
        _canReorder = await orderServiceInterface
            .checkProductVariationHasChanged(offlineCartList);
        _reorderMessage = !_canReorder
            ? 'this_ordered_products_are_updated_so_can_not_reorder_this_order'
            : '';
      }

      _isLoading = false;
      update();

      if (_canReorder) {
        await Get.find<CartController>()
            .reorderAddToCart(onlineCartList)
            .then((statusCode) {
          if (statusCode == 200) {
            Get.toNamed(RouteHelper.getCartRoute(fromReorder: true));
          }
        });
      } else {
        showCustomSnackBar(_reorderMessage.tr);
      }
    }
  }
}
