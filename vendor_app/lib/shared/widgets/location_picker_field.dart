import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

/// Champ de saisie des coordonnées géographiques de la boutique.
///
/// Affiche :
/// - Un bouton "Ma position" pour récupérer le GPS
/// - Une carte interactive OpenStreetMap (sans clé API)
/// - Les coordonnées sélectionnées (lat / lng)
/// - Un marqueur déplaçable sur la carte
class LocationPickerField extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final ValueChanged<LatLng?> onLocationChanged;

  const LocationPickerField({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationChanged,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _locating = false;

  // Coordonnées par défaut : Niamey, Niger
  static const LatLng _defaultCenter = LatLng(13.5137, 2.1098);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _locating = true);

    try {
      // 1. Vérifier si le service GPS est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Les services de localisation sont désactivés sur cet appareil.');
        return;
      }

      // 2. Vérifier / demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showError('Permission de localisation refusée.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Permission refusée définitivement. '
          'Veuillez l\'activer manuellement dans les paramètres de l\'application.',
        );
        return;
      }

      // 3. Récupérer la position (settings selon la plateforme)
      final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.other,
          timeLimit: const Duration(seconds: 15),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = latLng);
      _mapController.move(latLng, 16.0);
      widget.onLocationChanged(latLng);
    } on LocationServiceDisabledException {
      _showError('Le GPS est désactivé. Veuillez l\'activer dans les paramètres.');
    } on PermissionDeniedException {
      _showError('Permission de localisation refusée.');
    } catch (e) {
      _showError('Impossible d\'obtenir la position. Vérifiez que le GPS est activé.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedLocation = point);
    widget.onLocationChanged(point);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedLocation != null;
    final center = _selectedLocation ?? _defaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête de section ─────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.map_outlined, size: 16, color: AppColors.grey600),
            const SizedBox(width: 6),
            const Text(
              'Localisation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600,
              ),
            ),
            const Spacer(),
            // Bouton "Ma position"
            TextButton.icon(
              onPressed: _locating ? null : _getCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 16),
              label: const Text('Ma position', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Carte interactive ──────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasLocation ? AppColors.primary : AppColors.grey200,
                width: hasLocation ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: hasLocation ? 15.0 : 12.0,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.techinnov.vendor_app',
                ),
                if (hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Coordonnées affichées ou invite ───────────────────────────
        if (hasLocation)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lat : ${_selectedLocation!.latitude.toStringAsFixed(6)}'
                    '  ·  Lng : ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedLocation = null);
                    widget.onLocationChanged(null);
                  },
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.grey400),
                ),
              ],
            ),
          )
        else
          Text(
            'Appuyez sur la carte pour placer un marqueur, ou utilisez "Ma position".',
            style: TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
      ],
    );
  }
}
