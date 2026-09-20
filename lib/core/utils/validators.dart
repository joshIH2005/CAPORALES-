/// Validaciones de los formularios de la app.
class Validators {
  Validators._();

  static String? textoRequerido(String? value, {String campo = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  static String? soloLetras(String? value, {String campo = 'Campo'}) {
    final error = textoRequerido(value, campo: campo);
    if (error != null) return error;

    final soloLetras = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]+$");
    if (!soloLetras.hasMatch(value!.trim())) {
      return '$campo solo debe contener letras';
    }
    return null;
  }

  static String? numeroPositivo(String? value, {String campo = 'Campo'}) {
    final error = textoRequerido(value, campo: campo);
    if (error != null) return error;

    final numero = int.tryParse(value!.trim());
    if (numero == null || numero < 0 || numero > 120) {
      return 'Ingrese una edad valida (0-120)';
    }
    return null;
  }

  static String? fechaNoFutura(DateTime? value) {
    if (value == null) return 'Seleccione una fecha';
    if (value.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }
    return null;
  }

  /// Telefono opcional; si se ingresa, debe tener de 7 a 15 digitos.
  static String? telefonoOpcional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digitos = value.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(digitos)) {
      return 'Ingrese un telefono valido (7-15 digitos)';
    }
    return null;
  }
}
