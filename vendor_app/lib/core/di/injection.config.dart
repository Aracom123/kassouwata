// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_local_datasource.dart'
    as _i992;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i652;
import '../../features/onboarding/data/datasources/onboarding_datasource.dart'
    as _i1043;
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as _i792;
import '../../features/orders/data/datasources/order_remote_datasource.dart'
    as _i1007;
import '../../features/orders/data/repositories/order_repository_impl.dart'
    as _i376;
import '../../features/orders/domain/repositories/order_repository.dart'
    as _i543;
import '../../features/orders/presentation/bloc/order_bloc.dart' as _i298;
import '../../features/products/data/datasources/product_remote_datasource.dart'
    as _i333;
import '../../features/products/data/repositories/product_repository_impl.dart'
    as _i764;
import '../../features/products/domain/repositories/product_repository.dart'
    as _i963;
import '../../features/products/presentation/bloc/product_bloc.dart' as _i28;
import '../../features/shop/data/datasources/shop_remote_datasource.dart'
    as _i755;
import '../../features/tontine/data/datasources/tontine_remote_datasource.dart'
    as _i306;
import '../../features/tontine/data/repositories/tontine_repository_impl.dart'
    as _i43;
import '../../features/tontine/domain/repositories/tontine_repository.dart'
    as _i344;
import '../../features/tontine/presentation/bloc/tontine_bloc.dart' as _i806;
import '../network/dio_client.dart' as _i667;
import '../storage/secure_storage.dart' as _i619;
import 'injection.dart' as _i464;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.singleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.factory<_i992.AuthLocalDataSource>(
        () => _i992.AuthLocalDataSourceImpl(gh<_i460.SharedPreferences>()));
    gh.singleton<_i619.SecureStorage>(
        () => _i619.SecureStorage(gh<_i558.FlutterSecureStorage>()));
    gh.singleton<_i667.DioClient>(
        () => _i667.DioClient(gh<_i619.SecureStorage>()));
    gh.factory<_i1043.OnboardingDataSource>(
        () => _i1043.OnboardingDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i755.ShopRemoteDataSource>(
        () => _i755.ShopRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i306.TontineRemoteDataSource>(
        () => _i306.TontineRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i161.AuthRemoteDataSource>(
        () => _i161.AuthRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i1007.OrderRemoteDataSource>(
        () => _i1007.OrderRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i333.ProductRemoteDataSource>(
        () => _i333.ProductRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i543.OrderRepository>(
        () => _i376.OrderRepositoryImpl(gh<_i1007.OrderRemoteDataSource>()));
    gh.factory<_i298.OrderBloc>(
        () => _i298.OrderBloc(gh<_i543.OrderRepository>()));
    gh.factory<_i963.ProductRepository>(
        () => _i764.ProductRepositoryImpl(gh<_i333.ProductRemoteDataSource>()));
    gh.factory<_i792.OnboardingBloc>(() => _i792.OnboardingBloc(
          gh<_i1043.OnboardingDataSource>(),
          gh<_i992.AuthLocalDataSource>(),
        ));
    gh.factory<_i652.DashboardBloc>(() => _i652.DashboardBloc(
          gh<_i543.OrderRepository>(),
          gh<_i333.ProductRemoteDataSource>(),
          gh<_i306.TontineRemoteDataSource>(),
          gh<_i992.AuthLocalDataSource>(),
        ));
    gh.factory<_i344.TontineRepository>(
        () => _i43.TontineRepositoryImpl(gh<_i306.TontineRemoteDataSource>()));
    gh.factory<_i806.TontineBloc>(
        () => _i806.TontineBloc(gh<_i344.TontineRepository>()));
    gh.factory<_i787.AuthRepository>(() => _i153.AuthRepositoryImpl(
          gh<_i161.AuthRemoteDataSource>(),
          gh<_i992.AuthLocalDataSource>(),
          gh<_i619.SecureStorage>(),
        ));
    gh.factory<_i188.LoginUseCase>(
        () => _i188.LoginUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i48.LogoutUseCase>(
        () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i941.RegisterUseCase>(
        () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()));
    gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(
          gh<_i188.LoginUseCase>(),
          gh<_i941.RegisterUseCase>(),
          gh<_i48.LogoutUseCase>(),
          gh<_i787.AuthRepository>(),
        ));
    gh.factory<_i28.ProductBloc>(
        () => _i28.ProductBloc(gh<_i963.ProductRepository>()));
    return this;
  }
}

class _$RegisterModule extends _i464.RegisterModule {}
