import 'package:flutter/material.dart';

Color analizeColor(String code, double value) {
  const Color alert = Color(0xFFFF190C);
  const Color warning = Color(0xFFFAAD14);
  const Color success = Color(0xFF52C41A);

  switch (code) {
    case 'PH':
      if (value < 6.5 || value > 9) return alert;
      if (value >= 6.8 && value <= 8.5) return success;
      return warning;

    case 'CL': // Chlorures
      if (value > 250) return alert;
      if (value <= 200) return success;
      return warning;

    case 'SO4': // Sulfates
      if (value > 250) return alert;
      if (value <= 200) return success;
      return warning;

    case 'K': // Potassium
      if (value > 12) return alert;
      if (value <= 10) return success;
      return warning;

    case 'TH': // Titre hydrotimétrique
      // TH no es un contaminante → nunca "alert"
      if (value < 7) return success;          // très douce
      if (value <= 15) return success;        // douce
      if (value <= 25) return warning;        // moyennement dure
      if (value <= 42) return warning;        // dure
      return warning;                         // très dure

    default:
      return warning;
  }
}

Map<String, String> THCuality(double thValue) {
  if (thValue < 7) {
    return {
      'label': 'Très douce',
      'range': '< 7 °f',
      'level': 'success',
    };
  }

  if (thValue >= 7 && thValue < 15) {
    return {
      'label': 'Douce',
      'range': '7 – 15 °f',
      'level': 'success',
    };
  }

  if (thValue >= 15 && thValue < 25) {
    return {
      'label': 'Modérée',
      'range': '15 – 25 °f',
      'level': 'warning',
    };
  }

  if (thValue >= 25 && thValue <= 42) {
    return {
      'label': 'Dure',
      'range': '25 – 42 °f',
      'level': 'warning',
    };
  }

  return {
    'label': 'Très dure',
    'range': '> 42 °f',
    'level': 'warning',
  };
}
 

class Analize extends StatelessWidget {
  final Map<String, dynamic> item;

  const Analize({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final String code = item['code_parametre_se'];
    final double value = (item['resultat_numerique'] as num).toDouble();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(code),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                size: 16,
                color: analizeColor(code, value),
              ),
              const SizedBox(width: 5),
              Text(
                item['libelle_parametre'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (code == 'K')
                const Text('Qualité < 12 mg/L', style: TextStyle(fontSize: 12)),
              if (code == 'TH') ...[
                Text(
                  THCuality(value)['label']!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (code != 'K' &&
                  code != 'TH' &&
                  item['reference_qualite_parametre'] != null)
                Text(
                  'Qualité ${item['reference_qualite_parametre']}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['resultat_alphanumerique'],
                  style: TextStyle(
                    color: analizeColor(code, value),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item['libelle_unite'].contains('pH')
                    ? 'pH'
                    : item['libelle_unite'],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 5),
              Text(
                item['date_prelevement'].substring(0, 10),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*import 'package:flutter/material.dart';

Color analizeColor(String elem, double val) {
  const colors = {
    'alert': Color(0xFFFF190C),
    'warning': Color(0xFFFAAD14),
    'success': Color(0xFF52C41A),
    'primary': Color(0xFFBDBDBD)
  };

  final Map<String, Map<String, double>> ranges = {
    'PH': {'start': 6.5, 'end': 9, 'limit': 0.7},
    'CL': {'start': 0, 'end': 250, 'limit': 50},
    'SO4': {'start': 0, 'end': 250, 'limit': 25},
    'K': {'start': 0, 'end': 12, 'limit': 1.2},
    'TH': {'start': 0, 'end': 15, 'limit': 1.5}
  };

  final range = ranges[elem];
  if (range != null) {
    if (val < range['start']! || val > range['end']!) {
      return colors['alert']!;
    }
    if (range['start'] == 0 && val <= range['end']! - range['limit']!) {
      return colors['success']!;
    }
    if (val >= range['start']! + range['limit']! && val <= range['end']! - range['limit']!) {
      return colors['success']!;
    }
  }
  return colors['warning']!;
}

class Analize extends StatelessWidget {
  final Map<String, dynamic> item;

  const Analize({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    //debugPrint('---->>>> parametro: [ ${item} ]');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(item['code_parametre_se']),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science,
                  size: 16,
                  color: analizeColor(item['code_parametre_se'], item['resultat_numerique'])),
              const SizedBox(width: 5),
              Text(
                item['libelle_parametre'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (item['libelle_parametre'] == 'Potassium')
                const Text('Qualité < 12 mg/l', style: TextStyle(fontSize: 12)),
              if (item['libelle_parametre'] == 'Titre hydrotimétrique')
                const Text('Qualité < 15 °f', style: TextStyle(fontSize: 12)),
              if (item['libelle_parametre'] != 'Potassium' && item['reference_qualite_parametre'] != null)
                Text('Qualité ${item['reference_qualite_parametre'].contains('pH') ? item['reference_qualite_parametre'].replaceAll(RegExp(r'\s*unitÃ©\s*'), ' ').trim() : item['reference_qualite_parametre']}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  //color: analizeColor(item['code_parametre_se'], item['resultat_numerique']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['resultat_alphanumerique'],
                  style: TextStyle(color: analizeColor(item['code_parametre_se'], item['resultat_numerique'])),
                ),
              ),
              const SizedBox(width: 5),
              Text(item['libelle_unite'].contains('pH') ? 'pH' : item['libelle_unite']) ,
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 5),
              Text(item['date_prelevement'].substring(0, 10), style: const TextStyle(fontSize: 11),),
            ],
          ),
        ],
      ),
    );
  }
}*/
