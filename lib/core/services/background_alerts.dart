import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:convert';
import '../network/api_client.dart';
import 'device_reminders.dart';
const backgroundAlertTask='golden-gym-alerts';
@pragma('vm:entry-point')
void backgroundDispatcher(){
 Workmanager().executeTask((task,input)async{
  WidgetsFlutterBinding.ensureInitialized();DartPluginRegistrant.ensureInitialized();
  try{
   final prefs=await SharedPreferences.getInstance();if(prefs.getBool('gym.backgroundAlerts')!=true)return true;
   final api=ApiClient();await api.initialize();final token=api.token;if(token==null)return true;
   final profile=await api.storage.read(key:'gym.user');if(profile==null)return true;
   final uid=(jsonDecode(profile) as Map)['id'] as String;
   final alerts=await api.request('GET','/api/notifications') as List<dynamic>;
   final reminders=await api.request('GET','/api/reminders') as List<dynamic>;
   if(await api.storage.read(key:'gym.session')!=token)return true;
   final device=DeviceReminders();await device.initialize(requestPermission:false);await device.sync(reminders);
   final shown=prefs.getStringList('gym.alerts.$uid')?.toSet()??<String>{};
   for(final row in alerts){if(row['isRead']==true||shown.contains(row['id']))continue;await device.plugin.show(2000+shown.length,row['title'] as String,row['body'] as String,const NotificationDetails(android:AndroidNotificationDetails('gym_alerts','تنبيهات الجيم',channelDescription:'تحديثات الجيم عند المزامنة في الخلفية',importance:Importance.defaultImportance)));shown.add(row['id'] as String);}
   await prefs.setStringList('gym.alerts.$uid',shown.toList().reversed.take(80).toList());return true;
  }catch(_){return false;}
 });
}
Future<void> configureBackgroundAlerts(bool enabled)async{
 if(kIsWeb||defaultTargetPlatform!=TargetPlatform.android)return;
 if(enabled){await Workmanager().registerPeriodicTask(backgroundAlertTask,backgroundAlertTask,frequency:const Duration(minutes:15),constraints:Constraints(networkType:NetworkType.connected));}
 else{await Workmanager().cancelByUniqueName(backgroundAlertTask);}
}
