import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/categorie_model.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';

class AddProductPage extends StatefulWidget {
  final ProductEntity? product; // null = create, non-null = edit

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _quantiteCtrl = TextEditingController();
  final _nombreTranchesCtrl = TextEditingController();

  int? _idBoutique;
  bool _statut = true;

  // Catégories
  List<CategorieModel> _categories = [];
  int? _selectedCategorieId;

  // New images picked by user (local paths)
  String? _newImagePrincipalePath;
  final List<String> _newPhotosPaths = [];

  // Existing images from server (filenames)
  String? _existingImagePrincipale;
  List<String> _existingPhotos = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadBoutique();
    _loadCategories();
    if (_isEditing) {
      final p = widget.product!;
      _libelleCtrl.text = p.libelle;
      _descriptionCtrl.text = p.description ?? '';
      _prixCtrl.text = p.prixUnitaire.toString();
      _quantiteCtrl.text = p.quantite.toString();
      _statut = p.statut;
      _selectedCategorieId = p.categorie?.idCategorie;
      if (p.nombreTranches != null) {
        _nombreTranchesCtrl.text = p.nombreTranches.toString();
      }
      _existingImagePrincipale = p.imagePrincipale;
      _existingPhotos = p.photos?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
    }
  }

  Future<void> _loadBoutique() async {
    final boutique = await getIt<AuthLocalDataSource>().getCachedBoutique();
    if (mounted && boutique != null) {
      setState(() => _idBoutique = boutique.idBoutique);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await getIt<ProductRemoteDataSource>().getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _libelleCtrl.dispose();
    _descriptionCtrl.dispose();
    _prixCtrl.dispose();
    _quantiteCtrl.dispose();
    _nombreTranchesCtrl.dispose();
    super.dispose();
  }

  /// Affiche un BottomSheet pour choisir la source de l'image principale
  /// (caméra ou galerie), puis met à jour [_newImagePrincipalePath].
  Future<void> _pickMainImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 85);
    if (xfile != null) {
      setState(() => _newImagePrincipalePath = xfile.path);
    }
  }

  /// Affiche un BottomSheet pour choisir la source des photos supplémentaires.
  /// - Caméra : une seule photo prise sur le vif.
  /// - Galerie : sélection multiple depuis la bibliothèque.
  Future<void> _pickAdditionalPhotos() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (xfile != null) {
        setState(() => _newPhotosPaths.add(xfile.path));
      }
    } else {
      final xfiles = await picker.pickMultiImage(imageQuality: 85);
      if (xfiles.isNotEmpty) {
        setState(() => _newPhotosPaths.addAll(xfiles.map((x) => x.path)));
      }
    }
  }

  /// Affiche un BottomSheet avec les options Caméra et Galerie.
  /// Retourne [ImageSource.camera], [ImageSource.gallery], ou null si annulé.
  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.camera_alt),
                ),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Utiliser la caméra'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library),
                ),
                title: const Text('Choisir depuis la galerie'),
                subtitle: const Text('Sélectionner dans la bibliothèque'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    if (_idBoutique == null) return;

    final prix = double.tryParse(_prixCtrl.text.replaceAll(',', '.')) ?? 0;
    final quantite = int.tryParse(_quantiteCtrl.text) ?? 0;
    final nombreTranches = int.tryParse(_nombreTranchesCtrl.text.trim());

    if (_isEditing) {
      ctx.read<ProductBloc>().add(UpdateProduct(
            idProduit: widget.product!.idProduit,
            idBoutique: _idBoutique!,
            libelle: _libelleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            prixUnitaire: prix,
            quantite: quantite,
            statut: _statut,
            nombreTranches: nombreTranches,
            idCategorie: _selectedCategorieId,
            imagePrincipalePath: _newImagePrincipalePath,
            photosPaths: _newPhotosPaths.isNotEmpty ? _newPhotosPaths : null,
            existingImagePrincipale: _existingImagePrincipale,
            existingPhotos: _existingPhotos,
          ));
    } else {
      ctx.read<ProductBloc>().add(CreateProduct(
            idBoutique: _idBoutique!,
            libelle: _libelleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            prixUnitaire: prix,
            quantite: quantite,
            nombreTranches: nombreTranches,
            idCategorie: _selectedCategorieId,
            imagePrincipalePath: _newImagePrincipalePath,
            photosPaths: _newPhotosPaths.isNotEmpty ? _newPhotosPaths : null,
          ));
    }
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: const Text(
            'Voulez-vous vraiment supprimer ce produit ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ctx.read<ProductBloc>().add(DeleteProduct(widget.product!.idProduit));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>(),
      child: Builder(
        builder: (ctx) => BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              Navigator.of(context).pop();
            }
            if (state is ProductFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(_isEditing ? 'Modifier le produit' : 'Nouveau produit'),
              actions: _isEditing
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(ctx),
                      ),
                    ]
                  : null,
            ),
            body: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final isLoading = state is ProductLoading;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImagePrincipalePicker(),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _libelleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom du produit *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedCategorieId,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie *',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat.idCategorie,
                              child: Text(cat.libelle),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCategorieId = v),
                          validator: (v) => v == null ? 'Veuillez choisir une catégorie' : null,
                          hint: _categories.isEmpty
                              ? const Text('Chargement...')
                              : const Text('Sélectionner une catégorie'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _prixCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Prix unitaire (F) *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requis';
                                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                                    return 'Invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _quantiteCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Quantité *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requis';
                                  if (int.tryParse(v) == null) return 'Invalide';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nombreTranchesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de tranches (paiement prépayé)',
                            hintText: 'Ex : 3 (laisser vide si non applicable)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null; // optionnel
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 2) {
                              return 'Entrez un nombre entier ≥ 2, ou laissez vide';
                            }
                            return null;
                          },
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('Produit disponible'),
                            value: _statut,
                            onChanged: (v) => setState(() => _statut = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildAdditionalPhotosPicker(),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : () => _submit(ctx),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(_isEditing ? Icons.save : Icons.upload),
                          label: Text(_isEditing ? 'Enregistrer' : 'Publier le produit'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePrincipalePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image principale',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickMainImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _newImagePrincipalePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_newImagePrincipalePath!),
                          fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _removeButton(
                            () => setState(() => _newImagePrincipalePath = null)),
                      ),
                    ],
                  )
                : _existingImagePrincipale != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: ApiEndpoints.imageUrl(
                                AppConfig.baseUrl, _existingImagePrincipale!),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _removeButton(() => setState(
                                () => _existingImagePrincipale = null)),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 32, color: Colors.grey.shade400),
                              const SizedBox(width: 12),
                              Icon(Icons.photo_library_outlined,
                                  size: 32, color: Colors.grey.shade400),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Caméra ou Galerie',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Appuyer pour choisir',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalPhotosPicker() {
    final allPhotos = [
      ..._existingPhotos.map((f) => _PhotoItem(filename: f)),
      ..._newPhotosPaths.map((p) => _PhotoItem(localPath: p)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos supplémentaires',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (allPhotos.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allPhotos.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == allPhotos.length) {
                  return _addPhotoButton();
                }
                final item = allPhotos[i];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.localPath != null
                          ? Image.file(File(item.localPath!),
                              width: 90, height: 90, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: ApiEndpoints.imageUrl(
                                  AppConfig.baseUrl, item.filename!),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: _removeButton(() {
                        setState(() {
                          if (item.localPath != null) {
                            _newPhotosPaths.remove(item.localPath);
                          } else {
                            _existingPhotos.remove(item.filename);
                          }
                        });
                      }),
                    ),
                  ],
                );
              },
            ),
          )
        else
          _addPhotoButton(),
      ],
    );
  }

  Widget _addPhotoButton() {
    return GestureDetector(
      onTap: _pickAdditionalPhotos,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 26),
            const SizedBox(height: 4),
            Text('Ajouter',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }
}

class _PhotoItem {
  final String? filename;
  final String? localPath;
  const _PhotoItem({this.filename, this.localPath});
}
