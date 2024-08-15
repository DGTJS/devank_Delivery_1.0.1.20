import 'dart:async';

import 'package:stackfood_multivendor/common/widgets/rating_bar_widget.dart';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor/helper/date_converter.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/images.dart';
import 'package:stackfood_multivendor/util/styles.dart';
import 'package:stackfood_multivendor/features/order/widgets/address_details_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TrackDetailsView extends StatefulWidget {
  final OrderModel track;
  final Function callback;
  const TrackDetailsView({
    super.key,
    required this.track,
    required this.callback,
  });

  @override
  State<TrackDetailsView> createState() => _TrackDetailsViewState();
}

class _TrackDetailsViewState extends State<TrackDetailsView> {
  late Timer _timer;
  double distance = 0;

  @override
  void initState() {
    super.initState();
    // Inicia o Timer para atualizar a localização a cada 10 segundos
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateLocation();
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancela o Timer quando o widget é destruído
    super.dispose();
  }

  void _updateLocation() {
    setState(() {
      if (widget.track.deliveryMan != null) {
        distance = Geolocator.distanceBetween(
              double.parse(widget.track.deliveryAddress!.latitude!),
              double.parse(widget.track.deliveryAddress!.longitude!),
              double.parse(widget.track.deliveryMan!.lat ?? '0'),
              double.parse(widget.track.deliveryMan!.lng ?? '0'),
            ) /
            1000;
            setState(() {
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool takeAway = widget.track.orderType == 'take_away';
     if (widget.track.deliveryMan != null) {
      setState(() {
        distance = Geolocator.distanceBetween(
              double.parse(widget.track.deliveryAddress!.latitude!),
              double.parse(widget.track.deliveryAddress!.longitude!),
              double.parse(widget.track.deliveryMan!.lat ?? '0'),
              double.parse(widget.track.deliveryMan!.lng ?? '0'),
            ) /
            1000;
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeLarge,
          horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        color: Theme.of(context).cardColor,
      ),
      alignment: Alignment.center,
      child: (!takeAway && widget.track.deliveryMan == null)
          ? Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(children: [
                Text('estimate_delivery_time'.tr, style: robotoRegular),
                Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      DateConverter.differenceInMinute(
                                  widget.track.restaurant!.deliveryTime,
                                  widget.track.createdAt,
                                  widget.track.processingTime,
                                  widget.track.scheduleAt) <
                              5
                          ? '1 - 5'
                          : '${DateConverter.differenceInMinute(widget.track.restaurant!.deliveryTime, widget.track.createdAt, widget.track.processingTime, widget.track.scheduleAt) - 5} '
                              '- ${DateConverter.differenceInMinute(widget.track.restaurant!.deliveryTime, widget.track.createdAt, widget.track.processingTime, widget.track.scheduleAt)}',
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text('min'.tr,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeOverLarge)),
                  ]),
                ),
              ]),
            )
          : Column(children: [
              Container(
                height: 5,
                width: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text('estimate_delivery_time'.tr, style: robotoRegular),
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    DateConverter.differenceInMinute(
                                widget.track.restaurant!.deliveryTime,
                                widget.track.createdAt,
                                widget.track.processingTime,
                                widget.track.scheduleAt) <
                            5
                        ? '1 - 5'
                        : '${DateConverter.differenceInMinute(widget.track.restaurant!.deliveryTime, widget.track.createdAt, widget.track.processingTime, widget.track.scheduleAt) - 5} '
                            '- ${DateConverter.differenceInMinute(widget.track.restaurant!.deliveryTime, widget.track.createdAt, widget.track.processingTime, widget.track.scheduleAt)}',
                    style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeOverLarge),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text('min'.tr,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge)),
                ]),
              ),
              Divider(
                  color: Theme.of(context).disabledColor.withOpacity(0.3),
                  thickness: 1,
                  height: 30),
              takeAway
                  ? InkWell(
                      onTap: () async {
                        String url =
                            'https://www.google.com/maps/dir/?api=1&destination=${widget.track.restaurant != null ? widget.track.restaurant!.latitude : '0'}'
                            ',${widget.track.restaurant != null ? widget.track.restaurant!.longitude : '0'}&mode=d';
                        if (await canLaunchUrlString(url)) {
                          Get.find<OrderController>().cancelTimer();
                          await launchUrlString(url,
                              mode: LaunchMode.externalApplication);
                          Get.find<OrderController>().callTrackOrderApi(
                              orderModel:
                                  Get.find<OrderController>().trackModel!,
                              orderId: widget.track.id.toString());
                        } else {
                          showCustomSnackBar('unable_to_launch_google_map'.tr);
                        }
                        setState(() {
                          
                        });
                      },
                      child: Column(children: [
                        Icon(Icons.directions,
                            size: 25, color: Theme.of(context).primaryColor),
                        Text(
                          'direction'.tr,
                          style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ]),
                    )
                  : Column(children: [
                      Image.asset(Images.route,
                          height: 20,
                          width: 20,
                          color: Theme.of(context).primaryColor),
                      Text(
                        '${distance.toStringAsFixed(2)} ${'km'.tr}',
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ]),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Flexible(
                  child: Text(
                    takeAway
                        ? widget.track.deliveryAddress!.address!
                        : widget.track.deliveryMan!.location!,
                    style: robotoMedium.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color!
                            .withOpacity(0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 3),
                  color: Theme.of(context).disabledColor.withOpacity(0.3),
                  height: 20,
                  width: 3,
                ),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding:
                      const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Flexible(
                  child: takeAway
                      ? Text(
                          widget.track.restaurant != null
                              ? widget.track.restaurant!.address!
                              : '',
                          style: robotoMedium.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color!
                                  .withOpacity(0.7)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : AddressDetailsWidget(
                          addressDetails: widget.track.deliveryAddress),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Container(
                width: context.width,
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        takeAway
                            ? 'restaurant_details'.tr
                            : 'delivery_man_details'.tr,
                        style: robotoBold.copyWith(
                            color: Theme.of(context).disabledColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(children: [
                        ClipOval(
                            child: CustomImageWidget(
                          image:
                              '${takeAway ? widget.track.restaurant != null ? widget.track.restaurant!.logoFullUrl : '' : widget.track.deliveryMan!.imageFullUrl}',
                          height: 45,
                          width: 45,
                          fit: BoxFit.cover,
                        )),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                takeAway
                                    ? widget.track.restaurant != null
                                        ? widget.track.restaurant!.name!
                                        : 'no_restaurant_data_found'.tr
                                    : '${widget.track.deliveryMan!.fName} ${widget.track.deliveryMan!.lName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall),
                              ),
                              RatingBarWidget(
                                rating: takeAway
                                    ? widget.track.restaurant != null
                                        ? widget.track.restaurant!.avgRating
                                        : 0
                                    : widget.track.deliveryMan!.avgRating,
                                size: 15,
                                ratingCount: takeAway
                                    ? widget.track.restaurant != null
                                        ? widget.track.restaurant!.ratingCount
                                        : 0
                                    : widget.track.deliveryMan!.ratingCount,
                              ),
                            ])),
                        Get.find<AuthController>().isLoggedIn()
                            ? InkWell(
                                onTap: widget.callback as void Function()?,
                                child: Image.asset(Images.chatImageOrderDetails,
                                    height: 25, width: 25),
                              )
                            : const SizedBox(),
                        const SizedBox(width: Dimensions.paddingSizeLarge),
                        InkWell(
                          onTap: () async {
                            if (await canLaunchUrlString(
                                'tel:${takeAway ? widget.track.restaurant != null ? widget.track.restaurant!.phone : '' : widget.track.deliveryMan!.phone}')) {
                              launchUrlString(
                                  'tel:${takeAway ? widget.track.restaurant != null ? widget.track.restaurant!.phone : '' : widget.track.deliveryMan!.phone}',
                                  mode: LaunchMode.externalApplication);
                            } else {
                              showCustomSnackBar(
                                  '${'can_not_launch'.tr} ${takeAway ? widget.track.restaurant != null ? widget.track.restaurant!.phone : '' : widget.track.deliveryMan!.phone}');
                            }
                          },
                          child: Image.asset(Images.callImageOrderDetails,
                              height: 25, width: 25),
                        ),
                      ]),
                    ]),
              ),
            ]),
    );
  }
}
