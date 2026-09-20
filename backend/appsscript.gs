/**
 * ============================================================
 *  BACKEND: Caporales App <-> Google Sheets
 *  ------------------------------------------------------------
 *  1. Crea una hoja de calculo nueva en Google Drive.
 *  2. Copia este archivo en https://script.google.com (es.extensiones.google.com)
 *     como "Caporales Backend".
 *  3. Pega el ID de la hoja en 'SS_ID' (o recuerda el nombre y deja SS_ID = '').
 *  4. Implementa > Nuevo despliegue > App web:
 *       - Ejecutar como:  Yo
 *       - Acceso:         Cualquier persona (o Solo usuarios)
 *  5. Copia la URL del Web App y pegalá en
 *     lib/core/constants/api_config.dart (constante ApiConfig.baseUrl).
 * ============================================================
 */

// ID de la hoja de calculo. Si esta vacio, se busca por nombre 'Caporales'.
const SS_ID = '';

// Token secreto para autorizar peticiones.
// Debe coincidir con ApiConfig.tokenSecreto en lib/core/constants/api_config.dart.
const API_TOKEN = ''; // TODO: reemplazar por tu token.

// Clave para validar los QR firmados de los carnets (anti-falsificacion).
// Debe coincidir con ApiConfig.qrClaveSecreta en la app.
const QR_CLAVE = ''; // TODO: reemplazar por tu clave.

// Hojas internas (pestanas de tu spreadsheet).
const SHEET_INTEGRANTES = 'Integrantes';
const SHEET_REGISTROS = 'Registros';

/**
 * Punto de entrada GET: devuelve las estadisticas (integrantes + registros).
 * Todas las peticiones deben incluir el parametro "token" (autorizacion).
 */
function doGet(e) {
  if (e && e.parameter && e.parameter.accion === 'stats') {
    if (!tokenValido(e.parameter.token)) {
      return json({ ok: false, error: 'Token invalido' });
    }
    try {
      var ss = obtenerSpreadsheet();
      var integrantes = leerHoja(ss, SHEET_INTEGRANTES);
      var registros = leerHoja(ss, SHEET_REGISTROS);
      return json({
        ok: true,
        integrantes: integrantes,
        registros: registros,
      });
    } catch (error) {
      return json({ ok: false, error: error.toString() });
    }
  }

  // Escrituras via GET (retrocompatibilidad con versiones antiguas).
  // La app nueva usa POST; se mantiene por si existe una version sin actualizar.
  return procesarAccion(e && e.parameter);
}

/**
 * Punto de entrada POST: recibe los datos de la app y escribe en la hoja.
 *
 * NOTA: Apps Script responde a los POST con un 302 hacia la misma URL;
 * la app maneja el redirect manualmente y reenvia el cuerpo.
 */
function doPost(e) {
  try {
    var cuerpo = JSON.parse(e.postData.contents);
    var parametros = e.parameter || {};

    // El token puede ir en el cuerpo del JSON o como parametro en la URL.
    var token = cuerpo.token || parametros.token;
    if (token !== API_TOKEN) {
      return json({ ok: false, error: 'Token invalido' });
    }
    if (cuerpo.accion === 'stats') {
      return doGetStats();
    }

    cuerpo.datos = cuerpo.datos || {};
    var resultado = procesarAccion(cuerpo);
    return resultado;
  } catch (error) {
    return json({ ok: false, error: error.toString() });
  }
}

/** Ejecuta una accion de escritura sobre el spreadsheet. */
function procesarAccion(parametros) {
  var accion = parametros && parametros.accion;
  if (!accion) {
    return json({ ok: false, error: 'Accion no reconocida' });
  }

  if (!tokenValido(parametros.token)) {
    return json({ ok: false, error: 'Token invalido' });
  }

  var datos = null;
  if (parametros.datos) {
    try {
      datos = typeof parametros.datos === 'string'
        ? JSON.parse(parametros.datos)
        : parametros.datos;
    } catch (error) {
      return json({ ok: false, error: 'Error parseando datos: ' + error.toString() });
    }
  }

  try {
    var ss = obtenerSpreadsheet();

    switch (accion) {
      case 'nuevo_miembro':
        if (!datos) throw new Error('Datos faltantes');
        escribirIntegrante(ss, datos);
        return json({ ok: true, mensaje: 'Integrante registrado' });

      case 'actualizar_miembro':
        if (!datos) throw new Error('Datos faltantes');
        escribirIntegrante(ss, datos);
        return json({ ok: true, mensaje: 'Integrante actualizado' });

      case 'registrar_pago':
        if (!datos) throw new Error('Datos faltantes');
        escribirRegistro(ss, datos);
        return json({ ok: true, mensaje: 'Pago registrado' });

      case 'eliminar_registro':
        if (!datos) throw new Error('Datos faltantes');
        eliminarRegistro(ss, datos);
        return json({ ok: true, mensaje: 'Registro anulado' });

      default:
        return json({ ok: false, error: 'Accion no reconocida' });
    }
  } catch (error) {
    return json({ ok: false, error: error.toString() });
  }
}

/** Devuelve las estadisticas completas (integrantes + registros). */
function doGetStats() {
  try {
    var ss = obtenerSpreadsheet();
    var integrantes = leerHoja(ss, SHEET_INTEGRANTES);
    var registros = leerHoja(ss, SHEET_REGISTROS);
    return json({
      ok: true,
      integrantes: integrantes,
      registros: registros,
    });
  } catch (error) {
    return json({ ok: false, error: error.toString() });
  }
}

/** Verifica que el token coincida con API_TOKEN. */
function tokenValido(token) {
  return !!token && token === API_TOKEN;
}

// ============================================================
//  Utilidades de hoja
// ============================================================

/** Obtiene el spreadsheet (por ID o por nombre). */
function obtenerSpreadsheet() {
  if (SS_ID) {
    return SpreadsheetApp.openById(SS_ID);
  }
  var porNombre = DriveApp.getFilesByName('Caporales');
  if (porNombre.hasNext()) {
    var id = porNombre.next().getId();
    return SpreadsheetApp.openById(id);
  }
  throw new Error('No se encontro la hoja "Caporales". Verifica SS_ID.');
}

/** Lee una hoja completa y devuelve una lista de objetos (diccionarios). */
function leerHoja(ss, nombre) {
  var sheet = ss.getSheetByName(nombre);
  if (!sheet) {
    return [];
  }
  var valores = sheet.getDataRange().getValues();
  if (valores.length < 2) {
    return []; // Solo encabezados (o vacio).
  }

  // La primera fila son los encabezados = claves.
  var encabezados = valores[0];
  var filas = [];

  for (var i = 1; i < valores.length; i++) {
    var fila = valores[i];
    var objeto = {};
    for (var j = 0; j < encabezados.length; j++) {
      objeto[encabezados[j]] = fila[j];
    }
    filas.push(objeto);
  }
  return filas;
}

/** Escribe (o actualiza) un integrante en la hoja "Integrantes". */
function escribirIntegrante(ss, datos) {
  var sheet = ss.getSheetByName(SHEET_INTEGRANTES);

  // Crea la hoja y los encabezados si no existen.
  asegurarHoja(ss, SHEET_INTEGRANTES, INTEGRANTES_HEADERS);
  sheet = ss.getSheetByName(SHEET_INTEGRANTES);

  // Evita duplicados: si el ID ya existe, actualiza la fila.
  // Nota: si solo hay encabezados (ultimaFila === 1) no hay filas que revisar.
  var ultimaFila = sheet.getLastRow();
  if (ultimaFila > 1) {
    var ids = sheet.getRange(2, 1, ultimaFila - 1, 1).getValues();
    for (var i = 0; i < ids.length; i++) {
      if (ids[i][0] == datos.id) {
        var fila = i + 2;
        establecerFila(sheet, fila, INTEGRANTES_HEADERS, datos);
        return;
      }
    }
  }

  // Nuevo integrante: agrega al final.
  sheet.appendRow(mapear(INTEGRANTES_HEADERS, datos));
}

/** Escribe (o actualiza) un registro de pago en la hoja "Registros". */
function escribirRegistro(ss, datos) {
  asegurarHoja(ss, SHEET_REGISTROS, REGISTROS_HEADERS);
  var sheet = ss.getSheetByName(SHEET_REGISTROS);

  // Los registros siempre se agregan al final (orden cronologico).
  sheet.appendRow(mapear(REGISTROS_HEADERS, datos));
}

/** Elimina un registro de la hoja "Registros" buscandolo por su ID. */
function eliminarRegistro(ss, datos) {
  var sheet = ss.getSheetByName(SHEET_REGISTROS);
  if (!sheet || sheet.getLastRow() < 2) {
    throw new Error('No hay registros que eliminar');
  }
  var ultimaFila = sheet.getLastRow();
  var ids = sheet.getRange(2, 1, ultimaFila - 1, 1).getValues();
  for (var i = 0; i < ids.length; i++) {
    if (ids[i][0] == datos.id) {
      sheet.deleteRow(i + 2);
      return;
    }
  }
  throw new Error('Registro no encontrado: ' + datos.id);
}

/** Crea la hoja con encabezados si aun no existe y completa columnas nuevas. */
function asegurarHoja(ss, nombre, encabezados) {
  var sheet = ss.getSheetByName(nombre);
  if (!sheet) {
    sheet = ss.insertSheet(nombre);
    sheet.appendRow(encabezados);
    return;
  }
  // Completa encabezados faltantes (por ejemplo 'telefono' en hojas viejas).
  var actuales = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var faltantes = encabezados.filter(function (enc) {
    return actuales.indexOf(enc) === -1;
  });
  if (faltantes.length > 0) {
    var columna = sheet.getLastColumn() + 1;
    for (var i = 0; i < faltantes.length; i++) {
      sheet.getRange(1, columna + i).setValue(faltantes[i]);
    }
  }
}

/** Inserta en la fila indicada respetando el orden de encabezados. */
function establecerFila(sheet, fila, encabezados, datos) {
  var filaOrdenada = encabezados.map(function (encabezado) {
    return datos[encabezado];
  });
  sheet.getRange(fila, 1, 1, encabezados.length).setValues([filaOrdenada]);
}

/** Ordena los datos segun el orden de los encabezados. */
function mapear(encabezados, datos) {
  return encabezados.map(function (encabezado) {
    var valor = datos[encabezado];
    return valor === undefined ? '' : valor;
  });
}

// ============================================================
//  Encabezados de cada hoja (deben coincidir con los modelos Dart)
// ============================================================

var INTEGRANTES_HEADERS = [
  'id',
  'nombres_apellidos',
  'edad',
  'fecha_nacimiento',
  'ocupacion',
  'estado',
  'fecha_ingreso',
  'telefono',
  'foto_perfil',
];

var REGISTROS_HEADERS = [
  'id',
  'member_id',
  'member_name',
  'fecha',
  'hora',
  'monto',
  'asistencia',
];

// ============================================================
//  Respuestas JSON
// ============================================================

/** Devuelve una respuesta JSON formateada para la app. */
function json(objeto) {
  return ContentService.createTextOutput(JSON.stringify(objeto))
    .setMimeType(ContentService.MimeType.JSON);
}