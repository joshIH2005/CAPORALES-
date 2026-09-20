import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_gradients.dart';
import '../../core/utils/qr_firma.dart';
import '../../data/models/member_model.dart';

/// Carnet digital del integrante, disenado como tarjeta fisica.
///
/// Cabecera morada, QR negro sobre fondo blanco, nombre en mayusculas e ID.
/// Se usa tanto en pantalla como para capturar y compartir la imagen.
class CarnetDigitalWidget extends StatelessWidget {
  const CarnetDigitalWidget({
    super.key,
    required this.member,
    this.width = 340,
  });

  final Member member;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== Cabecera morada =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.groups, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELENCO DE DANZA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'CAPORALES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.qr_code_2, color: Colors.white, size: 28),
              ],
            ),
          ),

          // ===== Cuerpo del carnet =====
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // QR firmado: negro sobre fondo blanco
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: QrFirma.firmar(member.id),
                    version: QrVersions.auto,
                    size: 150,
                    backgroundColor: Colors.white,
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre en mayusculas
                Text(
                  member.nombreUpper,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                // Espacio para mostrar datos secundarios
                const SizedBox(height: 8),

                // ID del integrante
                Text(
                  'ID: ${member.id}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Envoltorio para capturar el carnet como imagen (usado por ShareCarnetButton).
class CarnetParaCaptura extends StatelessWidget {
  const CarnetParaCaptura({
    super.key,
    required this.member,
    this.padding = 24,
  });

  final Member member;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: CarnetDigitalWidget(
        member: member,
        width: 340,
      ),
    );
  }
}
