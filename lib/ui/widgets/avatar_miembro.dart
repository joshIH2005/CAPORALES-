import 'package:flutter/material.dart';

import '../../core/constants/app_gradients.dart';
import '../../data/models/member_model.dart';

/// Avatar circular de un integrante.
///
/// Muestra las iniciales sobre el fondo dorado de marca.
class AvatarMiembro extends StatelessWidget {
  const AvatarMiembro({
    super.key,
    required this.member,
    this.radius = 22,
  });

  final Member member;
  final double radius;

  String get _iniciales {
    final partes = member.nombresApellidos
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
      ),
      child: Text(
        _iniciales,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}
