import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:unorm_dart/unorm_dart.dart" as unorm;

const String REVERSE_URL = 'https://nominatim.openstreetmap.org';
const String QUALITY_URL = 'https://hubeau.eaufrance.fr/api/v1/qualite_eau_potable';

String upperAndClean(String str) {
  return unorm.nfd(str.toUpperCase()).replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  //return str.toUpperCase().normalize().replaceAll(RegExp(r'[\u0300-\u036f]'), '');
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
  final String apiUrl = '$QUALITY_URL/communes_udi?nom_commune=${upperAndClean(commune)}&annee=2023';

  try {
    final response = await http.get(Uri.parse(apiUrl));
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

Future<List<dynamic>> rawApiResults(String codeCommune) async {
  final String apiUrl =
      'https://hubeau.eaufrance.fr/api/v1/qualite_eau_potable/resultats_dis?code_commune=$codeCommune&code_parametre=1302,1338,1337,1367,1345&fields=libelle_parametre,code_lieu_analyse,resultat_numerique,libelle_unite,date_prelevement,code_parametre_se,code_parametre,reference_qualite_parametre,resultat_alphanumerique&date_min_prelevement=2021-01-01&sort=desc';

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

Future<Map<String, dynamic>> getReverseLocation(Map<String, dynamic> coord) async {
  final double lat = coord['latitude']!;
  final double lon = coord['longitude']!;
  final String url = '$REVERSE_URL/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';

  final response = await http.get(
    Uri.parse(url),
    headers: {'Accept-Language': 'en'},
  );

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