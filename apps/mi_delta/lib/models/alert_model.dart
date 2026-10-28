class AlertModel {
  final double rioLevel;
  final String rioStatus;
  final int temp;
  final String condition;
  final String windSpeed;
  final String alertMessage;

  const AlertModel({
    required this.rioLevel,
    required this.rioStatus,
    required this.temp,
    required this.condition,
    required this.windSpeed,
    required this.alertMessage,
  });

  static const AlertModel initial = AlertModel(
    rioLevel: 1.15,
    rioStatus: 'NORMAL',
    temp: 22,
    condition: 'Cielo Despejado',
    windSpeed: '12 km/h SE',
    alertMessage: 'Nivel fluvial en rango normal. Sin alerta de sudestada.',
  );
}
