import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:unorm_dart/unorm_dart.dart" as unorm;

const String reverseUrl = 'https://nominatim.openstreetmap.org';
const String qualityUrl = 'https://hubeau.eaufrance.fr/api/v1/qualite_eau_potable';



final last_year = DateTime.now().subtract(const Duration(days: 365));
final current_year = DateTime.now().year - 1;

// alternativa:
//final now = DateTime.now();
//final date = DateTime(now.year - 1, now.month, now.day);
//final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

/*String upperAndClean(String str) {
  return unorm.nfd(str.toUpperCase()).replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  //return str.toUpperCase().normalize().replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}*/

String upperAndClean(String str) {
  return unorm
      .nfd(str)
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '') // quita acentos
      .toUpperCase()
      .trim() // elimina espacios inicio/fin
       .replaceAll(RegExp(r'\s+'), '%20'); // 🔥 ESPACIO → flutter pub add another_telephony
      //.replaceAll(RegExp(r'\s+'), ' '); // colapsa espacios múltiples
}

Future<String?> getPlaceByZipCode(String code) async {
  final String apiUrl = 'http://api.geonames.org/postalCodeLookupJSON?postalcode=$code&country=FR&username=yuniormm';

  try {
    final response = await http.get(Uri.parse(apiUrl), headers: {'Accept-Language': 'fr'});
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['postalcodes'][0].containsKey('adminName2')) {
        return result['postalcodes'][0]['adminName2'];
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to load place');
    }
  } catch (error) {
    debugPrint('---Error---: Fn>getPlaceByZipCode>TryCatch: $error');
    return null;
  }
}


Future<dynamic> franceEuaCommune(String commune) async {
  try {
    final String apiUrl = '$qualityUrl/communes_udi?nom_commune=${upperAndClean(commune)}&annee=${current_year}';
    /*final apiUrl = Uri.parse(qualityUrl).replace(
      path: '${Uri.parse(qualityUrl).path}/communes_udi',
      queryParameters: {
        'nom_commune': upperAndClean(commune), // LE BLANC -> LE%20BLANC
        'annee': '2025',
      },
    );*/
    debugPrint("------------> api_url: ${apiUrl}");
    debugPrint("------------> api_url: ${Uri.parse(apiUrl)}");
    final response = await http.get(Uri.parse(apiUrl));
    //final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final data = result['data'];

      if (data.length > 1) {
        final filterData = data.where((e) => e['nom_commune'] == upperAndClean(commune)).toList();
        return filterData[0];
      } else if (data.length == 1) {
        return data[0];
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to load commune data');
    }
  } catch (error) {
    debugPrint('---Error---: Fn>franceEuaCommune>TryCatch: $error');
    return null;
  }
}


/*Future<Map<String, dynamic>?> franceEuaCommune(String commune) async {
  try {
    final String apiUrl =
        '$qualityUrl/communes_udi?nom_commune=${upperAndClean(commune)}&annee=2025';

    debugPrint("------------> api_url: $apiUrl");

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load commune data');
    }

    final Map<String, dynamic> result = jsonDecode(response.body);
    final List data = result['data'];

    if (data.isEmpty) {
      return null;
    }

    // Normalizamos el texto para comparar correctamente
    String normalize(String value) {
      return value
          .toUpperCase()
          .replaceAll(RegExp(r'\(.*?\)'), '') // elimina (LE)
          .replaceAll('-', ' ')
          .trim();
    }

    final String search = normalize(commune);

    final List filteredData = data.where((e) {
      final String apiCommune = normalize(e['nom_commune']);
      return apiCommune.contains(search) || search.contains(apiCommune);
    }).toList();

    if (filteredData.isNotEmpty) {
      return filteredData.first;
    }

    // fallback: devuelve el primero si no hubo match exacto
    return data.first;
  } catch (error) {
    debugPrint('---Error---: Fn>franceEuaCommune> $error');
    return null;
  }
}
*/

/*
Future<List<dynamic>> rawApiResults(String codeCommune) async {
  final String apiUrl =
      'https://hubeau.eaufrance.fr/api/v1/qualite_eau_potable/resultats_dis?code_commune=$codeCommune&code_parametre=1302,1338,1337,1367,1345&fields=libelle_parametre,code_lieu_analyse,resultat_numerique,libelle_unite,date_prelevement,code_parametre_se,code_parametre,reference_qualite_parametre,resultat_alphanumerique&date_min_prelevement=2025-05-01&sort=desc';
  debugPrint("------------> rawApiResults: ${apiUrl}");
  try {
    final response = await http.get(Uri.parse(apiUrl), headers: {'Accept-Language': 'fr'});
    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final rawData = responseJson['data'];

      Map<String, int> filterCount = {'ph': 0, 'cl': 0, 'sf': 0, 'pt': 0, 'th': 0};
      List<dynamic> filterData = [];

      rawData.forEach((e) {
        if (e['libelle_parametre'] == 'pH' && filterCount['ph'] == 0) {
          filterCount['ph'] = 1;
          filterData.add(e);
        }
        if (e['libelle_parametre'] == 'Sulfates' && filterCount['sf'] == 0) {
          filterCount['sf'] = 1;
          filterData.add(e);
        }
        if (e['libelle_parametre'] == 'Chlorures' && filterCount['cl'] == 0) {
          filterCount['cl'] = 1;
          filterData.add(e);
        }
        if (e['libelle_parametre'] == 'Potassium' && filterCount['pt'] == 0) {
          filterCount['pt'] = 1;
          filterData.add(e);
        }
        if (e['libelle_parametre'] == 'Titre hydrotimétrique' && filterCount['th'] == 0) {
          filterCount['th'] = 1;
          filterData.add(e);
        }
      });

      return filterData;
    } else {
      throw Exception('Failed to load raw API results');
    }
  } catch (error) {
    debugPrint('Error: rawApiResults $error');
    return [];
  }
}
*/


Future<List<Map<String, dynamic>>> rawApiResults(String codeCommune) async {
  final String apiUrl =
      'https://hubeau.eaufrance.fr/api/v1/qualite_eau_potable/resultats_dis'
      '?code_commune=$codeCommune'
      '&code_parametre=1302,1338,1337,1367,1345'
      '&fields=libelle_parametre,code_lieu_analyse,resultat_numerique,libelle_unite,'
      'date_prelevement,code_parametre_se,code_parametre,reference_qualite_parametre,'
      'resultat_alphanumerique'
      '&date_min_prelevement=${last_year}'
      '&sort=desc'
      '&size=5000';

  debugPrint("------------> rawApiResults: $apiUrl");

  try {
    final response =
        await http.get(Uri.parse(apiUrl), headers: {'Accept-Language': 'fr'});

    if (response.statusCode != 200) {
      throw Exception('Failed to load raw API results');
    }
    final Map<String, dynamic> responseJson = jsonDecode(utf8.decode(response.bodyBytes));
    //final Map<String, dynamic> responseJson = jsonDecode(response.body);
    final List rawData = responseJson['data'];

    /// Parámetros que queremos (primer valor = más reciente)
    final Set<String> wantedParams = {
      '1302', // pH
      '1337', // Chlorures
      '1338', // Sulfates
      '1367', // Potassium
      '1345', // Titre hydrotimétrique
    };

    final Map<String, Map<String, dynamic>> latestValues = {};

    for (final e in rawData) {
      final String code = e['code_parametre'];

      if (wantedParams.contains(code) && !latestValues.containsKey(code)) {
        latestValues[code] = Map<String, dynamic>.from(e);
      }
    }

    return latestValues.values.toList();
  } catch (error) {
    debugPrint('Error: rawApiResults $error');
    return [];
  }
}


Future<Map<String, dynamic>> getReverseLocation(Map<String, dynamic> coord) async {
  final double lat = coord['latitude']!;
  final double lon = coord['longitude']!;
  final String url = '$reverseUrl/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';

  //debugPrint("-----------url: ${url}");
  
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Accept-Language': 'en',
      'User-Agent': 'MiAppFlutter/1.0 (contacto@miapp.com)'},
    
  );
  //debugPrint("-----------response: ${response.request}");
  //debugPrint("-----------response.statusCode: ${response.statusCode}");
  if (response.statusCode == 200) {
    final Map<String, dynamic> result = jsonDecode(response.body);

    if (result['address'] != null) {
      //if (result['address']['country_code'] == 'fr') {
        if (result['address']['municipality'] != null) {
          final String coordsPlace = upperAndClean(result['address']['municipality']);
          result['address']['region'] = coordsPlace;
        } else if (result['address']['city'] != null) {
          final String coordsPlace = result['address']['state'];
          result['address']['region'] = coordsPlace;
        }
     // } else {
        //  other country, not work
        debugPrint(' "${result['address']['country_code']}" country');
        // debugPrint('not work in: "${result['address']['country_code']}" country');
     // }
    }
    debugPrint('--getReverseLocation--: ${result.entries}');
    return result;
  } else {
    throw Exception('Failed to load reverse location');
  }
}

/*region: coordsPlace, name: result.address.country, code: result.address.country_code */
/*franceCommune(UpperAndClean(result.address.village.toUpperCase()));
console.log('........ Address.........')
console.log( result.address )
console.log('........ Village .........')
console.log( result.address.village )
console.log('........ Commune.........')
});
}*/


// DATA FOR DEV
Map <String, dynamic> testCoord = {
    'a': { 'latitude': 46.085037347169276, 'longitude': -1.0897710114953731 },
    'b': { 'latitude': 46.05982906636687, 'longitude': -0.8818062152214191 },
    'c': { 'latitude': 46.21683964652038, 'longitude': -0.664826229058995 },
    'd': { 'latitude': 46.711612412813054, 'longitude': -0.23747993776014828 },
    'e': { 'latitude': 46.23964025401055, 'longitude': -1.5505989573802832 },
    'f': { 'latitude': 45.979779680846846, 'longitude': 0.5384294885904917 },
    'g': { 'latitude': 46.54940977326188, 'longitude': -0.2587659534032208 },
    'h': { 'latitude': 42.1417049082428, 'longitude': 12.123060812289117 },
    'i': { 'latitude': 43.03021626252355, 'longitude': 11.416479153074194 },
    'j': { 'latitude': 46.11270352458801, 'longitude': 4.898093448982785 }
};