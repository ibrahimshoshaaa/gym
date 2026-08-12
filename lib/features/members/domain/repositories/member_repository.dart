import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/member.dart';

abstract class MemberRepository {
  Stream<List<Member>> watchMembers();

  /// ستريم لسجل عضو واحد بس - ده اللي لازم العضو نفسه يستخدمه
  /// (بدل watchMembers) عشان Firestore rules بتسمح له يقرأ سجله هو
  /// بس، ومحاولة قراءة الجدول كله بتترفض بالكامل حتى لو سجله موجود فيه
  Stream<Member?> watchMemberById(String id);

  Future<Either<Failure, Member>> getMemberById(String id);
  Future<Either<Failure, Member>> addMember(Member member);
  Future<Either<Failure, void>> updateMember(Member member);
  Future<Either<Failure, void>> deleteMember(String id);
  Future<Either<Failure, List<Member>>> searchMembers(String query);
}
