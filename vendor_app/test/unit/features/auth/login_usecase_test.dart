import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vendor_app/core/error/failures.dart';
import 'package:vendor_app/features/auth/domain/entities/user_entity.dart';
import 'package:vendor_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vendor_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vendor_app/shared/enums/user_status.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const tUser = UserEntity(
    idUser: 'uuid-1',
    telephone: '+22670000000',
    status: UserStatus.active,
  );

  const tParams = LoginParams(telephone: '+22670000000', password: 'password123');

  test('doit retourner UserEntity en cas de succès', () async {
    when(() => mockRepository.login(
          telephone: any(named: 'telephone'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Right(tUser));

    final result = await useCase(tParams);

    expect(result, const Right(tUser));
    verify(() => mockRepository.login(
          telephone: tParams.telephone,
          password: tParams.password,
        )).called(1);
  });

  test('doit retourner ServerFailure en cas d\'erreur serveur', () async {
    when(() => mockRepository.login(
          telephone: any(named: 'telephone'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(ServerFailure('Erreur serveur')));

    final result = await useCase(tParams);

    expect(result, const Left(ServerFailure('Erreur serveur')));
  });

  test('doit retourner UnauthorizedFailure pour des identifiants incorrects', () async {
    when(() => mockRepository.login(
          telephone: any(named: 'telephone'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(UnauthorizedFailure('Identifiants incorrects')));

    final result = await useCase(tParams);

    expect(result.isLeft(), true);
  });
}