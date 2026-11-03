import 'package:flutter/material.dart';

class TrainingModality {
  const TrainingModality(this.label, this.icon);

  final String label;
  final IconData icon;
}

const trainingModalities = <String, TrainingModality>{
  'gym': TrainingModality('Muscula\u00e7\u00e3o', Icons.fitness_center),
  'cycling': TrainingModality('Ciclismo', Icons.directions_bike),
  'running': TrainingModality('Corrida', Icons.directions_run),
  'aerobic': TrainingModality('Aer\u00f3bico', Icons.monitor_heart_outlined),
  'combat': TrainingModality('Combate', Icons.sports_martial_arts),
  'swimming': TrainingModality('Nata\u00e7\u00e3o', Icons.pool),
  'walking': TrainingModality('Caminhada', Icons.directions_walk),
  'crossfit': TrainingModality('Cross Training', Icons.local_fire_department),
  'yoga': TrainingModality('Yoga & Pilates', Icons.self_improvement),
  'hiking': TrainingModality('Trilha / Hiking', Icons.terrain),
  'basketball': TrainingModality('Basquete', Icons.sports_basketball),
  'soccer': TrainingModality('Futebol', Icons.sports_soccer),
  'tennis': TrainingModality('T\u00eanis / Beach Tennis', Icons.sports_tennis),
  'climbing': TrainingModality('Escalada', Icons.landscape),
  'skate': TrainingModality('Skate / Patins', Icons.directions),
  'functional': TrainingModality('Funcional', Icons.bolt),
  'hiit': TrainingModality('HIIT', Icons.timer),
  'dance': TrainingModality('Dan\u00e7a', Icons.music_note),
  'rowing': TrainingModality('Remo', Icons.rowing),
  'other': TrainingModality('Outros', Icons.more_horiz),
};

const gpsModalityActivities = <String, String>{
  'running': 'Corrida',
  'cycling': 'Ciclismo',
  'walking': 'Caminhada',
  'hiking': 'Trilha',
};
