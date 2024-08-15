import 'package:stackfood_multivendor/features/notification/domain/models/notification_model.dart';
import 'package:stackfood_multivendor/features/notification/domain/service/notification_service_interface.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController implements GetxService {
  final NotificationServiceInterface notificationServiceInterface;
  NotificationController({required this.notificationServiceInterface});

  List<NotificationModel>? _notificationList;
  List<NotificationModel>? get notificationList => _notificationList;

  bool _hasNotification = false;
  bool get hasNotification => _hasNotification;

  Future<int> getNotificationList(bool reload) async {
    if(_notificationList == null || reload) {
      _notificationList = await notificationServiceInterface.getList();
      // Ensure _notificationList is not null before accessing its length
      if(_notificationList != null && _notificationList!.isNotEmpty) {
        _hasNotification = _notificationList!.length != (getSeenNotificationCount() ?? 0);
      } else {
        _hasNotification = false;
      }
      update();
    }
    // Return 0 if _notificationList is null to avoid further errors
    return _notificationList?.length ?? 0;
  }

  void saveSeenNotificationCount(int count) {
    notificationServiceInterface.saveSeenNotificationCount(count);
  }

  int? getSeenNotificationCount() {
    return notificationServiceInterface.getSeenNotificationCount();
  }

  void clearNotification() {
    _notificationList = null;
  }

  void addSeenNotificationId(int id) {
    List<int> idList = [];
    idList.addAll(notificationServiceInterface.getNotificationIdList());
    idList.add(id);
    notificationServiceInterface.addSeenNotificationIdList(idList);
    update();
  }

  List<int>? getSeenNotificationIdList() {
    return notificationServiceInterface.getNotificationIdList();
  }
}
