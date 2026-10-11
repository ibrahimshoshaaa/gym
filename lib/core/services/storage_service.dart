import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';

class StorageService {
  Future<String> uploadMemberPhoto({required String gymId, required String memberId, required File file}) async {
    if (await file.length() > 2 * 1024 * 1024) throw const ApiException(0, 'الصورة أكبر من ٢ ميجا، اختار صورة أصغر');
    final setup = await ApiClient.instance.request('POST', '/api/photos/upload', {'gymId':gymId,'memberId':memberId}) as Map<String,dynamic>;
    final request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/${setup['cloudName']}/image/upload'));
    request.fields.addAll(Map<String,String>.from(setup['fields'] as Map));
    request.files.add(await http.MultipartFile.fromPath('file',file.path));
    final response = await request.send().timeout(const Duration(seconds:30));
    final body = await response.stream.bytesToString().timeout(const Duration(seconds:30));
    if (response.statusCode != 200) throw const ApiException(0,'تعذر رفع الصورة، حاول تاني');
    return (jsonDecode(body) as Map<String,dynamic>)['secure_url'] as String;
  }
  Future<void> deleteMemberPhoto({required String gymId,required String memberId}) async {
    await ApiClient.instance.request('POST','/api/photos/delete',{'gymId':gymId,'memberId':memberId});
  }
}
