part of 'catalogue_bloc.dart';

abstract class CatalogueEvent extends Equatable {
  const CatalogueEvent();
  @override
  List<Object?> get props => [];
}

class LoadCatalogue extends CatalogueEvent {
  const LoadCatalogue();
}

class SearchCatalogue extends CatalogueEvent {
  final String query;
  const SearchCatalogue(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends CatalogueEvent {
  final int? categorieId;
  const FilterByCategory(this.categorieId);
  @override
  List<Object?> get props => [categorieId];
}
