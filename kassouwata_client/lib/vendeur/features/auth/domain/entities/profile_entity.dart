import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final int idProfile;
  final String libelle;
  final String? description;

  const ProfileEntity({
    required this.idProfile,
    required this.libelle,
    this.description,
  });

  @override
  List<Object?> get props => [idProfile, libelle];
}