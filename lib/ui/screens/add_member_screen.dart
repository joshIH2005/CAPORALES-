import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/member_model.dart';
import '../../logic/member_controller.dart';
import '../widgets/carnet_digital_widget.dart';
import '../widgets/gradient_button.dart';
import '../widgets/share_carnet_button.dart';

/// Formulario de alta de integrante.
///
/// Al guardar: genera el ID, envia a la API y muestra el Carnet Digital
/// para compartirlo como imagen.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key, required this.controller});

  final MemberController controller;

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _telefonoController = TextEditingController();

  DateTime? _fechaNacimiento;
  Uint8List? _fotoBytes;
  bool _guardando = false;
  Member? _miembroCreado;

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _ocupacionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  /// Abre el selector para elegir la foto de perfil (galeria o camara).
  Future<void> _seleccionarFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaryLight),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primaryLight),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origen == null || !mounted) return;

    try {
      final foto = await ImagePicker().pickImage(
        source: origen,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (foto == null || !mounted) return;
      final bytes = await foto.readAsBytes();
      setState(() => _fotoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar la foto. Intente de nuevo.'),
          ),
        );
      }
    }
  }

  /// Abre el selector de fecha de nacimiento.
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento',
    );
    if (fecha != null) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  /// Valida el formulario, crea el integrante y muestra el carnet.
  Future<void> _guardar() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) return;
    final fechaError = Validators.fechaNoFutura(_fechaNacimiento);
    if (fechaError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fechaError)),
      );
      return;
    }

    setState(() => _guardando = true);

    final (ok, mensaje, creado) = await widget.controller.crearMiembro(
      nombresApellidos: _nombreController.text.trim(),
      edad: int.parse(_edadController.text.trim()),
      fechaNacimiento: _fechaNacimiento!.toIso8601String().substring(0, 10),
      ocupacion: _ocupacionController.text.trim().isEmpty
          ? 'No especificada'
          : _ocupacionController.text.trim(),
      telefono: _telefonoController.text.trim(),
      fotoPerfil: _fotoBytes == null ? '' : base64Encode(_fotoBytes!),
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (!ok || creado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
      return;
    }

    // Verificación: registra éxito y muestra el carnet.
    setState(() => _miembroCreado = creado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$mensaje: ${creado.id}')),
    );
  }

  /// Limpia el formulario para registrar otro integrante.
  void _registrarOtro() {
    setState(() {
      _miembroCreado = null;
      _formKey.currentState?.reset();
      _nombreController.clear();
      _edadController.clear();
      _ocupacionController.clear();
      _telefonoController.clear();
      _fotoBytes = null;
      _fechaNacimiento = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nuevo integrante'),
      ),
      body: _miembroCreado == null
          ? _buildFormulario()
          : _buildCarnetSection(_miembroCreado!),
    );
  }

  // ===== Formulario de registro =====
  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Encabezado visual =====
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: AppColors.primaryLight, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registro de nuevo integrante',
                          style: AppTextStyles.headline(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completa los datos. El ID se genera automáticamente.',
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ===== Foto de perfil (opcional) =====
            Center(
              child: InkWell(
                onTap: _seleccionarFoto,
                borderRadius: BorderRadius.circular(60),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.surface,
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.6), width: 2),
                  ),
                  child: _fotoBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            _fotoBytes!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.goldLight, size: 30),
                            SizedBox(height: 6),
                            Text(
                              'Foto de perfil',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== Nombres y apellidos =====
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  Validators.soloLetras(v, campo: 'Nombre completo'),
              decoration: _inputDecoration(
                label: 'Nombres y apellidos',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 16),

            // ===== Edad =====
            TextFormField(
              controller: _edadController,
              keyboardType: TextInputType.number,
              validator: (v) => Validators.numeroPositivo(v, campo: 'Edad'),
              decoration: _inputDecoration(
                label: 'Edad',
                icon: Icons.cake_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // ===== Fecha de nacimiento =====
            InkWell(
              onTap: _seleccionarFecha,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Fecha de nacimiento',
                  icon: Icons.event_outlined,
                ),
                child: Text(
                  _fechaNacimiento == null
                      ? 'Seleccionar fecha'
                      : Formatters.fechaCorta(_fechaNacimiento!),
                  style: TextStyle(
                    color: _fechaNacimiento == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Ocupacion =====
            TextFormField(
              controller: _ocupacionController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                label: 'Ocupacion (opcional)',
                icon: Icons.work_outline,
              ),
            ),
            const SizedBox(height: 16),

            // ===== Telefono (opcional) =====
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              validator: Validators.telefonoOpcional,
              decoration: _inputDecoration(
                label: 'Telefono (opcional)',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 28),

            // ===== Boton guardar =====
            GradientButton(
              onPressed: _guardando ? null : _guardar,
              loading: _guardando,
              icon: Icons.person_add_alt_1,
              label: 'Registrar integrante',
            ),
          ],
        ),
      ),
    );
  }

  // ===== Seccion del carnet digital =====
  Widget _buildCarnetSection(Member member) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Carnet Digital',
            style: AppTextStyles.headline(context),
          ),
          const SizedBox(height: 6),
          Text(
            'Este QR generará el cobro al ser escaneado.',
            style: AppTextStyles.body(context),
          ),
          const SizedBox(height: 24),

          // Carnet como tarjeta fisica
          CarnetDigitalWidget(member: member),

          const SizedBox(height: 24),

          // Compartir como imagen
          ShareCarnetButton(member: member),

          const SizedBox(height: 12),

          // Registrar otro integrante
          TextButton(
            onPressed: _registrarOtro,
            child: const Text('Registrar otro integrante'),
          ),
        ],
      ),
    );
  }

  /// Decoracion estandar de los campos del formulario.
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryLight),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
