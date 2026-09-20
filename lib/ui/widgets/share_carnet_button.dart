import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/member_model.dart';
import 'carnet_digital_widget.dart';
import 'gradient_button.dart';

/// Boton que captura el carnet digital como imagen (PNG) y
/// abre el menu "Compartir" del sistema para enviarlo.
class ShareCarnetButton extends StatefulWidget {
  const ShareCarnetButton({
    super.key,
    required this.member,
  });

  final Member member;

  @override
  State<ShareCarnetButton> createState() => _ShareCarnetButtonState();
}

class _ShareCarnetButtonState extends State<ShareCarnetButton> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _sharing = false;

  Future<void> _capturarYCompartir() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      // En la web no se puede abrir la hoja de compartir de Android;
      // se muestra un aviso.
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Compartir imagen esta disponible en la version Android de la app.',
              ),
            ),
          );
        }
        return;
      }

      // 1. Captura el widget del carnet como imagen PNG (calidad 2x).
      final Uint8List bytes = await _screenshotController.captureFromWidget(
        CarnetParaCaptura(member: widget.member),
        pixelRatio: 2.0,
        context: context,
      );

      // 2. Abre el ShareSheet del sistema (Android / iOS).
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'carnet_${widget.member.id}.png',
          ),
        ],
        text:
            'Carnet digital de ${widget.member.nombresApellidos} - ID: ${widget.member.id}',
      );
    } catch (e) {
      debugPrint('Error al compartir el carnet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el carnet. Intente de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: _sharing ? null : _capturarYCompartir,
      loading: _sharing,
      icon: Icons.share,
      label: _sharing ? 'Compartiendo...' : 'Compartir carnet',
    );
  }
}
