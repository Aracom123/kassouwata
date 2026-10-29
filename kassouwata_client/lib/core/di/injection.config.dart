// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'package:kassouwata_client/core/di/injection.dart' as _i497;
import 'package:kassouwata_client/core/network/dio_client.dart' as _i1069;
import 'package:kassouwata_client/core/storage/secure_storage.dart' as _i429;

// Auth
import 'package:kassouwata_client/features/auth/data/datasources/auth_remote_datasource.dart' as _i484;
import 'package:kassouwata_client/features/auth/data/repositories/auth_repository_impl.dart' as _i680;
import 'package:kassouwata_client/features/auth/domain/repositories/auth_repository.dart' as _i58;
import 'package:kassouwata_client/features/auth/domain/usecases/login_usecase.dart' as _i193;
import 'package:kassouwata_client/features/auth/domain/usecases/register_usecase.dart' as _i314;
import 'package:kassouwata_client/features/auth/presentation/bloc/auth_bloc.dart' as _i603;

// Profile
import 'package:kassouwata_client/features/profile/data/datasources/profile_remote_datasource.dart' as _i232;
import 'package:kassouwata_client/features/profile/data/repositories/profile_repository_impl.dart' as _i1007;
import 'package:kassouwata_client/features/profile/domain/repositories/profile_repository.dart' as _i719;
import 'package:kassouwata_client/features/profile/domain/usecases/complete_profile_usecase.dart' as _i340;
import 'package:kassouwata_client/features/profile/presentation/bloc/complete_profile_bloc.dart' as _i21;

// Cart
import 'package:kassouwata_client/features/cart/presentation/bloc/cart_bloc.dart' as _i_cart_bloc;

// Catalogue
import 'package:kassouwata_client/features/catalogue/data/datasources/catalogue_remote_datasource.dart' as _i_cat_ds;
import 'package:kassouwata_client/features/catalogue/data/repositories/catalogue_repository_impl.dart' as _i_cat_repo;
import 'package:kassouwata_client/features/catalogue/domain/repositories/catalogue_repository.dart' as _i_cat_repo_abs;
import 'package:kassouwata_client/features/catalogue/domain/usecases/get_products_usecase.dart' as _i_cat_uc;
import 'package:kassouwata_client/features/catalogue/presentation/bloc/catalogue_bloc.dart' as _i_cat_bloc;

// Boutique
import 'package:kassouwata_client/features/boutique/data/datasources/boutique_remote_datasource.dart' as _i_bout_ds;
import 'package:kassouwata_client/features/boutique/data/repositories/boutique_repository_impl.dart' as _i_bout_repo;
import 'package:kassouwata_client/features/boutique/domain/repositories/boutique_repository.dart' as _i_bout_repo_abs;
import 'package:kassouwata_client/features/boutique/presentation/bloc/boutique_bloc.dart' as _i_bout_bloc;

// Orders
import 'package:kassouwata_client/features/orders/data/datasources/order_remote_datasource.dart' as _i_ord_ds;
import 'package:kassouwata_client/features/orders/data/repositories/order_repository_impl.dart' as _i_ord_repo;
import 'package:kassouwata_client/features/orders/domain/repositories/order_repository.dart' as _i_ord_repo_abs;
import 'package:kassouwata_client/features/orders/presentation/bloc/order_bloc.dart' as _i_ord_bloc;

// Tontine
import 'package:kassouwata_client/features/tontine/data/datasources/tontine_client_datasource.dart' as _i_ton_ds;
import 'package:kassouwata_client/features/tontine/data/repositories/tontine_client_repository_impl.dart' as _i_ton_repo;
import 'package:kassouwata_client/features/tontine/domain/repositories/tontine_client_repository.dart' as _i_ton_repo_abs;
import 'package:kassouwata_client/features/tontine/presentation/bloc/tontine_client_bloc.dart' as _i_ton_bloc;

// Paiements en ligne
import 'package:kassouwata_client/features/paiement/data/paiement_service.dart' as _i_paie;

// Espace vendeur (« Ma boutique »)
import 'package:shared_preferences/shared_preferences.dart' as _i_prefs;
import 'package:kassouwata_client/vendeur/vendeur_session.dart' as _i_vs;
import 'package:kassouwata_client/vendeur/features/auth/data/datasources/auth_local_datasource.dart' as _i_v_local;
import 'package:kassouwata_client/vendeur/features/shop/data/datasources/shop_remote_datasource.dart' as _i_v_shop;
import 'package:kassouwata_client/vendeur/features/onboarding/data/datasources/onboarding_datasource.dart' as _i_v_onb_ds;
import 'package:kassouwata_client/vendeur/features/onboarding/presentation/bloc/onboarding_bloc.dart' as _i_v_onb_bloc;
import 'package:kassouwata_client/vendeur/features/orders/data/datasources/order_remote_datasource.dart' as _i_v_ord_ds;
import 'package:kassouwata_client/vendeur/features/orders/data/repositories/order_repository_impl.dart' as _i_v_ord_repo;
import 'package:kassouwata_client/vendeur/features/orders/domain/repositories/order_repository.dart' as _i_v_ord_repo_abs;
import 'package:kassouwata_client/vendeur/features/orders/presentation/bloc/order_bloc.dart' as _i_v_ord_bloc;
import 'package:kassouwata_client/vendeur/features/products/data/datasources/product_remote_datasource.dart' as _i_v_prod_ds;
import 'package:kassouwata_client/vendeur/features/products/data/repositories/product_repository_impl.dart' as _i_v_prod_repo;
import 'package:kassouwata_client/vendeur/features/products/domain/repositories/product_repository.dart' as _i_v_prod_repo_abs;
import 'package:kassouwata_client/vendeur/features/products/presentation/bloc/product_bloc.dart' as _i_v_prod_bloc;
import 'package:kassouwata_client/vendeur/features/tontine/data/datasources/tontine_remote_datasource.dart' as _i_v_ton_ds;
import 'package:kassouwata_client/vendeur/features/dashboard/presentation/bloc/dashboard_bloc.dart' as _i_v_dash;

extension GetItInjectableX on _i174.GetIt {
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();

    // ── Core ──────────────────────────────────────────────────────────────────
    gh.singleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.singleton<_i429.SecureStorage>(
        () => _i429.SecureStorage(gh<_i558.FlutterSecureStorage>()));
    gh.singleton<_i1069.DioClient>(
        () => _i1069.DioClient(gh<_i429.SecureStorage>()));

    // ── Espace vendeur : session (cache utilisateur + boutique) ──────────────
    // SharedPreferences est enregistré dans configureDependencies().
    gh.factory<_i_v_local.AuthLocalDataSource>(() =>
        _i_v_local.AuthLocalDataSourceImpl(gh<_i_prefs.SharedPreferences>()));
    gh.factory<_i_v_shop.ShopRemoteDataSource>(
        () => _i_v_shop.ShopRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.lazySingleton<_i_vs.VendeurSession>(() => _i_vs.VendeurSession(
          gh<_i_v_local.AuthLocalDataSource>(),
          gh<_i_v_shop.ShopRemoteDataSource>(),
          gh<_i429.SecureStorage>(),
        ));

    // ── Auth ──────────────────────────────────────────────────────────────────
    gh.factory<_i484.AuthRemoteDataSource>(
        () => _i484.AuthRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i58.AuthRepository>(() => _i680.AuthRepositoryImpl(
          gh<_i484.AuthRemoteDataSource>(),
          gh<_i429.SecureStorage>(),
          gh<_i_vs.VendeurSession>(),
        ));
    gh.factory<_i193.LoginUseCase>(
        () => _i193.LoginUseCase(gh<_i58.AuthRepository>()));
    gh.factory<_i314.RegisterUseCase>(
        () => _i314.RegisterUseCase(gh<_i58.AuthRepository>()));
    gh.factory<_i603.AuthBloc>(() => _i603.AuthBloc(
          gh<_i193.LoginUseCase>(),
          gh<_i314.RegisterUseCase>(),
          gh<_i429.SecureStorage>(),
          gh<_i58.AuthRepository>(),
        ));

    // ── Profile ───────────────────────────────────────────────────────────────
    gh.factory<_i232.ProfileRemoteDataSource>(
        () => _i232.ProfileRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i719.ProfileRepository>(() => _i1007.ProfileRepositoryImpl(
          gh<_i232.ProfileRemoteDataSource>(),
          gh<_i429.SecureStorage>(),
        ));
    gh.factory<_i340.CompleteProfileUseCase>(
        () => _i340.CompleteProfileUseCase(gh<_i719.ProfileRepository>()));
    gh.factory<_i21.CompleteProfileBloc>(() => _i21.CompleteProfileBloc(
          gh<_i340.CompleteProfileUseCase>(),
          gh<_i719.ProfileRepository>(),
        ));

    // ── Cart ──────────────────────────────────────────────────────────────────
    gh.factory<_i_cart_bloc.CartBloc>(() => _i_cart_bloc.CartBloc());

    // ── Catalogue ─────────────────────────────────────────────────────────────
    gh.factory<_i_cat_ds.CatalogueRemoteDataSource>(
        () => _i_cat_ds.CatalogueRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_cat_repo_abs.CatalogueRepository>(
        () => _i_cat_repo.CatalogueRepositoryImpl(
            gh<_i_cat_ds.CatalogueRemoteDataSource>()));
    gh.factory<_i_cat_uc.GetProductsUseCase>(
        () => _i_cat_uc.GetProductsUseCase(
            gh<_i_cat_repo_abs.CatalogueRepository>()));
    gh.factory<_i_cat_uc.GetProductByIdUseCase>(
        () => _i_cat_uc.GetProductByIdUseCase(
            gh<_i_cat_repo_abs.CatalogueRepository>()));
    gh.factory<_i_cat_uc.GetCategoriesUseCase>(
        () => _i_cat_uc.GetCategoriesUseCase(
            gh<_i_cat_repo_abs.CatalogueRepository>()));
    gh.factory<_i_cat_bloc.CatalogueBloc>(() => _i_cat_bloc.CatalogueBloc(
          gh<_i_cat_uc.GetProductsUseCase>(),
          gh<_i_cat_uc.GetCategoriesUseCase>(),
        ));

    // ── Boutique ──────────────────────────────────────────────────────────────
    gh.factory<_i_bout_ds.BoutiqueRemoteDataSource>(
        () => _i_bout_ds.BoutiqueRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_bout_repo_abs.BoutiqueRepository>(
        () => _i_bout_repo.BoutiqueRepositoryImpl(
            gh<_i_bout_ds.BoutiqueRemoteDataSource>()));
    gh.factory<_i_bout_bloc.BoutiqueBloc>(
        () => _i_bout_bloc.BoutiqueBloc(
            gh<_i_bout_repo_abs.BoutiqueRepository>()));

    // ── Orders ────────────────────────────────────────────────────────────────
    gh.factory<_i_ord_ds.OrderRemoteDataSource>(
        () => _i_ord_ds.OrderRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_ord_repo_abs.OrderRepository>(
        () => _i_ord_repo.OrderRepositoryImpl(
              gh<_i_ord_ds.OrderRemoteDataSource>(),
              gh<_i429.SecureStorage>(),
            ));
    gh.factory<_i_ord_bloc.OrderBloc>(
        () => _i_ord_bloc.OrderBloc(gh<_i_ord_repo_abs.OrderRepository>()));

    // ── Tontine ───────────────────────────────────────────────────────────────
    gh.factory<_i_ton_ds.TontineClientDataSource>(
        () => _i_ton_ds.TontineClientDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_ton_repo_abs.TontineClientRepository>(
        () => _i_ton_repo.TontineClientRepositoryImpl(
            gh<_i_ton_ds.TontineClientDataSource>()));
    gh.factory<_i_ton_bloc.TontineClientBloc>(
        () => _i_ton_bloc.TontineClientBloc(
            gh<_i_ton_repo_abs.TontineClientRepository>()));

    // ── Paiements en ligne ──────────────────────────────────────────────────
    gh.lazySingleton<_i_paie.PaiementService>(
        () => _i_paie.PaiementService(gh<_i1069.DioClient>()));

    // ── Espace vendeur : boutique, produits, commandes reçues, tableau de bord
    gh.factory<_i_v_onb_ds.OnboardingDataSource>(
        () => _i_v_onb_ds.OnboardingDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_v_onb_bloc.OnboardingBloc>(() => _i_v_onb_bloc.OnboardingBloc(
          gh<_i_v_onb_ds.OnboardingDataSource>(),
          gh<_i_v_local.AuthLocalDataSource>(),
        ));
    gh.factory<_i_v_ord_ds.OrderRemoteDataSource>(
        () => _i_v_ord_ds.OrderRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_v_ord_repo_abs.OrderRepository>(() =>
        _i_v_ord_repo.OrderRepositoryImpl(gh<_i_v_ord_ds.OrderRemoteDataSource>()));
    gh.factory<_i_v_ord_bloc.OrderBloc>(() =>
        _i_v_ord_bloc.OrderBloc(gh<_i_v_ord_repo_abs.OrderRepository>()));
    gh.factory<_i_v_prod_ds.ProductRemoteDataSource>(
        () => _i_v_prod_ds.ProductRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_v_prod_repo_abs.ProductRepository>(() =>
        _i_v_prod_repo.ProductRepositoryImpl(
            gh<_i_v_prod_ds.ProductRemoteDataSource>()));
    gh.factory<_i_v_prod_bloc.ProductBloc>(() =>
        _i_v_prod_bloc.ProductBloc(gh<_i_v_prod_repo_abs.ProductRepository>()));
    gh.factory<_i_v_ton_ds.TontineRemoteDataSource>(
        () => _i_v_ton_ds.TontineRemoteDataSourceImpl(gh<_i1069.DioClient>()));
    gh.factory<_i_v_dash.DashboardBloc>(() => _i_v_dash.DashboardBloc(
          gh<_i_v_ord_repo_abs.OrderRepository>(),
          gh<_i_v_prod_ds.ProductRemoteDataSource>(),
          gh<_i_v_local.AuthLocalDataSource>(),
        ));

    return this;
  }
}

class _$RegisterModule extends _i497.RegisterModule {}
