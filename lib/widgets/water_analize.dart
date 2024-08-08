import 'package:flutter/material.dart';

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

  const Analize({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[400],
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
              SizedBox(width: 5),
              Text(
                item['libelle_parametre'],
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              if (item['libelle_parametre'] == 'Potassium')
                Text('Qualité < 12 mg/l', style: TextStyle(fontSize: 12)),
              if (item['libelle_parametre'] == 'Titre hydrotimétrique')
                Text('Qualité < 15 °f', style: TextStyle(fontSize: 12)),
              if (item['libelle_parametre'] != 'Potassium' && item['reference_qualite_parametre'] != null)
                Text('Qualité ${item['reference_qualite_parametre']}', style: TextStyle(fontSize: 12)),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: analizeColor(item['code_parametre_se'], item['resultat_numerique']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['resultat_alphanumerique'],
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 5),
              Text(item['libelle_unite']),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.black),
              SizedBox(width: 5),
              Text(item['date_prelevement'].substring(0, 10)),
            ],
          ),
        ],
      ),
    );
  }
}
