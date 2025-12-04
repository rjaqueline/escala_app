import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ATENÇÃO: agora usamos as datas 100% reais de 2024
// e os deslocamentos oficiais de cada uma:
final Map<String, DateTime> datasBaseEscalas2024 = {
  "1B": DateTime(2024, 1, 3),
  "2B": DateTime(2024, 1, 5),
  "1D": DateTime(2024, 1, 8),
  "2D": DateTime(2024, 1, 10),
  "1A": DateTime(2024, 1, 13),
  "2A": DateTime(2024, 1, 15),
  "1C": DateTime(2024, 1, 18),
  "2C": DateTime(2024, 1, 20),
};

// deslocamentos reais dentro do ciclo
final Map<String, int> turmasDeslocamento = {
  "1A": 0,
  "1B": 2,
  "1C": 5,
  "1D": 7,
  "2A": 10,
  "2B": 12,
  "2C": 15,
  "2D": 17,
};

class ProximoMesPage extends StatelessWidget {
  final String escala; // 1A, 1B, 1C, etc.

  const ProximoMesPage({super.key, required this.escala});

  // -------- GERAR ESCALA DO PRÓXIMO MÊS --------
  List<Map<String, dynamic>> gerarEscalaDoMes() {
    final hoje = DateTime.now();
    final proximoMes = DateTime(hoje.year, hoje.month + 1, 1);
    final ultimoDia = DateTime(proximoMes.year, proximoMes.month + 1, 0).day;

    final dataBase = datasBaseEscalas2024[escala]!;
    final deslocamento = turmasDeslocamento[escala]!;

    // base ajustada (igual main.dart)
    final baseCorrigida = dataBase.add(Duration(days: deslocamento));
    final baseLimpa = DateTime(
      baseCorrigida.year,
      baseCorrigida.month,
      baseCorrigida.day,
    );

    final List<Map<String, dynamic>> dias = [];

    for (int dia = 1; dia <= ultimoDia; dia++) {
      final data = DateTime(proximoMes.year, proximoMes.month, dia);
      final dataLimpa = DateTime(data.year, data.month, data.day);
      final diasDecorridos = dataLimpa.difference(baseLimpa).inDays;

      // >>> MESMA LÓGICA CORRETA do motor principal
      final ciclo = ((diasDecorridos % 20) + 20) % 20;
      final status = (ciclo < 12) ? "Embarcada" : "De folga";

      dias.add({"data": data, "status": status});
    }

    return dias;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM');
    final dias = gerarEscalaDoMes();
    final hoje = DateTime.now();
    final proximoMes = DateTime(hoje.year, hoje.month + 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Escala $escala – ${toBeginningOfSentenceCase(DateFormat.MMMM("pt_BR").format(proximoMes))} ${proximoMes.year}',
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF483D8B),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40), // <-- AQUI
        itemCount: dias.length,
        itemBuilder: (context, index) {
          final item = dias[index];
          final data = item["data"] as DateTime;
          final status = item["status"] as String;
          final embarcada = status == "Embarcada";

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: embarcada ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: embarcada ? Colors.red.shade200 : Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      embarcada
                          ? Icons
                                .directions_bus_filled_rounded // ÔNIBUS LINDO 🚌
                          : Icons
                                .airline_seat_individual_suite, // REDEZINHA 🛏️💚
                      color: embarcada
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      df.format(data),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: embarcada
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: embarcada
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
