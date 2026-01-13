enum Turno { embarque, folga }

// Normaliza a data (remove hora/minuto/segundo)
DateTime norm(DateTime d) => DateTime(d.year, d.month, d.day);

final Map<String, DateTime> datasBaseEscalas = {
  "1B": DateTime(2026, 2, 1),
  "2B": DateTime(2026, 2, 3),
  "1D": DateTime(2026, 2, 6),
  "2D": DateTime(2026, 2, 8),
  "1A": DateTime(2026, 2, 11),
  "2A": DateTime(2026, 2, 13),
  "1C": DateTime(2026, 2, 16),
  "2C": DateTime(2026, 2, 18),
};

Turno calcularTurno(DateTime dia, DateTime base) {
  final diff = norm(dia).difference(norm(base)).inDays;
  final ciclo = ((diff % 20) + 20) % 20;
  return ciclo < 12 ? Turno.embarque : Turno.folga;
}
