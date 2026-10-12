import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/services/background_alerts.dart';
import '../../../core/services/device_reminders.dart';
import '../../../core/widgets/gym_ui.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  ConsumerState<NotificationSettingsScreen> createState()=>_NotificationSettingsState();
}
class _NotificationSettingsState extends ConsumerState<NotificationSettingsScreen>{
  bool _busy=false;
  Future<void> _toggle(bool enabled)async{
    setState(()=>_busy=true);
    try{
      if(enabled)await DeviceReminders().initialize();
      await configureBackgroundAlerts(enabled);
      await ref.read(sharedPreferencesProvider).setBool('gym.backgroundAlerts',enabled);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>GymScaffold(appBar:AppBar(title:const Text('إعدادات التنبيهات')),body:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('تذكيرات الاشتراك والحصص بتتجهز على جهازك بعد فتح التطبيق، وبتحتاج السماح بالإشعارات.'),
    const SizedBox(height:16),
    SwitchListTile(value:ref.read(sharedPreferencesProvider).getBool('gym.backgroundAlerts')==true,onChanged:_busy?null:_toggle,title:const Text('مزامنة التنبيهات في الخلفية'),subtitle:const Text('على أندرويد: مراجعة التحديثات كل ١٥ دقيقة تقريبًا مع الإنترنت. نظام توفير البطارية ممكن يؤخرها. افتح التطبيق لتحديث فوري.')),
    const SizedBox(height:16),
    OutlinedButton(onPressed:_busy?null:()async{try{await DeviceReminders().initialize();}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},child:const Text('السماح بتذكيرات الجهاز')),
  ]));
}
