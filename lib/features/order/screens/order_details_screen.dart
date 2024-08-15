import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_dialog_widget.dart';
import 'package:stackfood_multivendor/common/widgets/footer_view_widget.dart';
import 'package:stackfood_multivendor/common/widgets/menu_drawer_widget.dart';
import 'package:stackfood_multivendor/common/widgets/web_page_title_widget.dart';
import 'package:stackfood_multivendor/features/checkout/widgets/offline_success_dialog.dart';
import 'package:stackfood_multivendor/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor/features/order/domain/models/subscription_schedule_model.dart';
import 'package:stackfood_multivendor/features/order/widgets/bottom_view_widget.dart';
import 'package:stackfood_multivendor/features/order/widgets/order_info_section.dart';
import 'package:stackfood_multivendor/features/order/widgets/order_pricing_section.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_details_model.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor/helper/date_converter.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/styles.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final int? orderId;
  final bool fromOfflinePayment;
  final String? contactNumber;
  final bool fromGuestTrack;

  const OrderDetailsScreen({
    Key? key,
    required this.orderModel,
    required this.orderId,
    this.contactNumber,
    this.fromOfflinePayment = false,
    this.fromGuestTrack = false,
  }) : super(key: key);

  @override
  OrderDetailsScreenState createState() => OrderDetailsScreenState();
}

class OrderDetailsScreenState extends State<OrderDetailsScreen> with WidgetsBindingObserver {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  Future<void> _loadData() async {
    final orderController = Get.find<OrderController>();
    final splashController = Get.find<SplashController>();

    try {
      await orderController.trackOrder(widget.orderId.toString(), widget.orderModel, false, contactNumber: widget.contactNumber);
      if (widget.fromOfflinePayment) {
        Future.delayed(const Duration(seconds: 2), () => showAnimatedDialog(context, OfflineSuccessDialog(orderId: widget.orderId)));
      }

      if (widget.orderModel == null) {
        await splashController.getConfigData();
      }
      await Future.wait([
        orderController.getOrderCancelReasons(),
        orderController.getOrderDetails(widget.orderId.toString()),
      ]);

      if (orderController.trackModel != null) {
        orderController.callTrackOrderApi(
          orderModel: orderController.trackModel!,
          orderId: widget.orderId.toString(),
          contactNumber: widget.contactNumber,
        );
      }
    } catch (e) {
      // Adicione um tratamento de erro adequado aqui
      print('Error loading data: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final orderController = Get.find<OrderController>();
    if (state == AppLifecycleState.resumed) {
      if (orderController.trackModel != null) {
        orderController.callTrackOrderApi(
          orderModel: orderController.trackModel!,
          orderId: widget.orderId.toString(),
          contactNumber: widget.contactNumber,
        );
      }
    } else if (state == AppLifecycleState.paused) {
      orderController.cancelTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.find<OrderController>().cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (val) async {
        if ((widget.orderModel == null || widget.fromOfflinePayment) && !widget.fromGuestTrack) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else if (widget.fromGuestTrack) {
          return;
        } else {
          return;
        }
      },
      child: GetBuilder<OrderController>(builder: (orderController) {
        final order = orderController.trackModel;
        final orderDetails = orderController.orderDetails;

        if (order == null || orderDetails == null) {
          return Scaffold(
            appBar: CustomAppBarWidget(title: 'order_details'.tr),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final double deliveryCharge = order.orderType == 'delivery' ? order.deliveryCharge ?? 0 : 0;
        final double itemsPrice = orderDetails.fold(0.0, (sum, detail) => sum + (detail.price! * detail.quantity!));
        final double addOns = orderDetails.fold(0.0, (sum, detail) => sum + detail.addOns!.fold(0.0, (sum, addOn) => sum + (addOn.price! * addOn.quantity!)));
        final double discount = order.couponDiscountAmount ?? 0;
        final double couponDiscount = order.couponDiscountAmount ?? 0;
        final double tax = order.totalTaxAmount ?? 0;
        final double additionalCharge = order.additionalCharge ?? 0;
        final double extraPackagingCharge = order.extraPackagingAmount ?? 0;
        final double referrerBonusAmount = order.referrerBonusAmount ?? 0;
        final double dmTips = order.dmTips ?? 0;
        final bool showChatPermission = order.restaurant != null &&
            (order.restaurant!.restaurantModel == 'commission' || (order.restaurant!.restaurantSubscription?.chat ?? 0) == 1);

        final double subTotal = itemsPrice + addOns;
        final double total = itemsPrice + addOns - discount + (order.taxStatus ?? false ? 0 : tax) + deliveryCharge - couponDiscount + dmTips + additionalCharge + extraPackagingCharge - referrerBonusAmount;

        return Scaffold(
          appBar: _buildAppBar(order),
          endDrawer: const MenuDrawerWidget(),
          endDrawerEnableOpenDragGesture: false,
          body: SafeArea(
            child: Column(
              children: [
                WebScreenTitleWidget(title: 'order_details'.tr),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: FooterViewWidget(
                      child: SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: ResponsiveHelper.isDesktop(context)
                            ? _buildDesktopLayout(order, orderController, total, itemsPrice, addOns, discount, couponDiscount, tax, dmTips, deliveryCharge, additionalCharge, extraPackagingCharge, referrerBonusAmount, showChatPermission)
                            : _buildMobileLayout(order, orderController, total, itemsPrice, addOns, discount, couponDiscount, tax, dmTips, deliveryCharge, additionalCharge, extraPackagingCharge, referrerBonusAmount, showChatPermission),
                      ),
                    ),
                  ),
                ),
                if (!ResponsiveHelper.isDesktop(context))
                  BottomViewWidget(
                    orderController: orderController,
                    order: order,
                    orderId: widget.orderId,
                    total: total,
                    contactNumber: widget.contactNumber,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(OrderModel order) {
    bool isSubscription = order.subscription != null;
    if (isSubscription && !ResponsiveHelper.isDesktop(context)) {
      return AppBar(
        surfaceTintColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            Text('${'subscription'.tr} # ${order.id.toString()}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text('${'your_order_is'.tr} ${order.orderStatus}', style: robotoRegular.copyWith(color: Theme.of(context).primaryColor)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _onBackPressed(),
        ),
        actions: const [SizedBox()],
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      );
    } else {
      return CustomAppBarWidget(
        title: isSubscription ? 'subscription_details'.tr : 'order_details'.tr,
        onBackPressed: _onBackPressed,
      );
    }
  }

  void _onBackPressed() {
    if ((widget.orderModel == null || widget.fromOfflinePayment) && !widget.fromGuestTrack) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else if (widget.fromGuestTrack) {
      Get.back();
    } else {
      Get.back();
    }
  }

  Widget _buildDesktopLayout(
    OrderModel order,
    OrderController orderController,
    double total,
    double itemsPrice,
    double addOns,
    double discount,
    double couponDiscount,
    double tax,
    double dmTips,
    double deliveryCharge,
    double additionalCharge,
    double extraPackagingCharge,
    double referrerBonusAmount,
    bool showChatPermission,
  ) {
    List<String> schedules = _buildSchedules(order, orderController);

    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                if (order.subscription != null)
                  Text('${'subscription'.tr} # ${order.id.toString()}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                 SizedBox(height: order.subscription != null ? Dimensions.paddingSizeExtraSmall : 0),
                if (order.subscription != null)
                  Text('${'your_order_is'.tr} ${order.orderStatus}', style: robotoRegular.copyWith(color: Theme.of(context).primaryColor)),
                 SizedBox(height: order.subscription != null ? Dimensions.paddingSizeLarge : 0),
                OrderInfoSection(
                  order: order,
                  orderController: orderController,
                  schedules: schedules,
                  showChatPermission: showChatPermission,
                  contactNumber: widget.contactNumber,
                  totalAmount: total,
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeLarge),
          Expanded(
            flex: 4,
            child: OrderPricingSection(
              itemsPrice: itemsPrice,
              addOns: addOns,
              order: order,
              subTotal: itemsPrice + addOns,
              discount: discount,
              couponDiscount: couponDiscount,
              tax: tax,
              dmTips: dmTips,
              deliveryCharge: deliveryCharge,
              total: total,
              orderController: orderController,
              orderId: widget.orderId,
              contactNumber: widget.contactNumber,
              extraPackagingAmount: extraPackagingCharge,
              referrerBonusAmount: referrerBonusAmount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    OrderModel order,
    OrderController orderController,
    double total,
    double itemsPrice,
    double addOns,
    double discount,
    double couponDiscount,
    double tax,
    double dmTips,
    double deliveryCharge,
    double additionalCharge,
    double extraPackagingCharge,
    double referrerBonusAmount,
    bool showChatPermission,
  ) {
    List<String> schedules = _buildSchedules(order, orderController);

    return Column(
      children: [
        OrderInfoSection(
          order: order,
          orderController: orderController,
          schedules: schedules,
          showChatPermission: showChatPermission,
          contactNumber: widget.contactNumber,
          totalAmount: total,
        ),
        OrderPricingSection(
          itemsPrice: itemsPrice,
          addOns: addOns,
          order: order,
          subTotal: itemsPrice + addOns,
          discount: discount,
          couponDiscount: couponDiscount,
          tax: tax,
          dmTips: dmTips,
          deliveryCharge: deliveryCharge,
          total: total,
          orderController: orderController,
          orderId: widget.orderId,
          contactNumber: widget.contactNumber,
          extraPackagingAmount: extraPackagingCharge,
          referrerBonusAmount: referrerBonusAmount,
        ),
      ],
    );
  }

  List<String> _buildSchedules(OrderModel order, OrderController orderController) {
    List<String> schedules = [];
    if (order.subscription != null) {
      if (order.subscription!.type == 'weekly') {
        List<String> weekDays = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        for (SubscriptionScheduleModel schedule in orderController.schedules!) {
          schedules.add('${weekDays[schedule.day!].tr} (${DateConverter.convertTimeToTime(schedule.time!)})');
        }
      } else if (order.subscription!.type == 'monthly') {
        for (SubscriptionScheduleModel schedule in orderController.schedules!) {
          schedules.add('${'day_capital'.tr} ${schedule.day} (${DateConverter.convertTimeToTime(schedule.time!)})');
        }
      } else {
        schedules.add(DateConverter.convertTimeToTime(orderController.schedules![0].time!));
      }
    }
    return schedules;
  }
}
