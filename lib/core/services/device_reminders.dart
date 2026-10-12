import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import '../network/api_client.dart';
class DeviceReminders {
 final FlutterLocalNotificationsPlugin plugin;
 bool _ready=false;
 String? _signature;
 DeviceReminders({FlutterLocalNotificationsPlugin? plugin}):plugin=plugin??FlutterLocalNotificationsPlugin();
 Future<void> initialize({bool requestPermission=true})async{
  if(_ready||kIsWeb)return;
  zones.initializeTimeZones();
  await plugin.initialize(const InitializationSettings(android:AndroidInitializationSettings('notification_icon'),iOS:DarwinInitializationSettings(requestAlertPermission:false,requestBadgePermission:false,requestSoundPermission:false)));
  if(requestPermission)await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  if(requestPermission)await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert:true,badge:true,sound:true);
  _ready=true;
 }
 Future<void> sync(List<dynamic> reminders)async{
  if(kIsWeb)return;
  await initialize();
  final fingerprint=reminders.map((r){final at=r['at'];return '${r['id']}:${at is DbTimestamp?at.toDate().toIso8601String():at.toString()}';}).join('|');
  if(fingerprint==_signature)return;
  for(var i=0;i<40;i++){await plugin.cancel(1000+i);}
  for(var i=0;i<reminders.length && i<40;i++){
   final row=reminders[i] as Map,at=row['at'];
   final date=at is DbTimestamp?at.toDate():DateTime.parse((at as Map)['value'] as String);
   var scheduled=tz.TZDateTime.from(date,tz.getLocation('Africa/Cairo'));
   if(row['kind']=='expiry')scheduled=tz.TZDateTime(scheduled.location,scheduled.year,scheduled.month,scheduled.day,10);
   if(scheduled.isBefore(tz.TZDateTime.now(scheduled.location)))continue;
   await plugin.zonedSchedule(1000+i,row['title'] as String,row['body'] as String,scheduled,const NotificationDetails(android:AndroidNotificationDetails('gym_reminders','تذكيرات الجيم',channelDescription:'الاشتراكات والحصص المحجوزة',importance:Importance.defaultImportance,priority:Priority.defaultPriority),iOS:DarwinNotificationDetails()),androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle);
  }
  _signature=fingerprint;
 }
 Future<void> clear()async{_signature=null;if(_ready)await plugin.cancelAll();}
}
