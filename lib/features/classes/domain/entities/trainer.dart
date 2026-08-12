import 'package:equatable/equatable.dart';

class Trainer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? specialty;
  final bool isActive;

  const Trainer({
    required this.id,
    required this.name,
    required this.phone,
    this.specialty,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, phone, specialty, isActive];
}
