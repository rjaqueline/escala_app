import 'package:escala_app/escala_12x8.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProximoMesPage extends StatelessWidget {
  final String escala;
  final int ano;
  final int mes;

  const ProximoMesPage({
    super.key,
    required this.escala,
    required this.ano,
    required this.mes,
  });
  // -------- GERAR ESCALA DO PRÓXIMO MÊS --------
  List<Map<String, dynamic>> gerarEscalaDoMes() {
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    final base = datasBaseEscalas[escala]!;

    final lista = <Map<String, dynamic>>[];

    for (int dia = 1; dia <= ultimoDia; dia++) {
      final data = DateTime(ano, mes, dia);
      final turno = calcularTurno(data, base);

      lista.add({'data': data, 'turno': turno});
    }

    return lista;
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
    'Escala $escala – ${toBeginningOfSentenceCase(
      DateFormat.MMMM("pt_BR").format(DateTime(ano, mes)),
    )} $ano',
  ),
  centerTitle: true,
  backgroundColor: const Color(0xFF483D8B),
),

      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        itemCount: dias.length,
        itemBuilder: (context, index) {
          final item = dias[index];
          final data = item['data'] as DateTime;
          final turno = item['turno'] as Turno;

          final embarcada = turno == Turno.embarque;
          final status = embarcada ? "Embarcada" : "Folga";

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: embarcada ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: embarcada ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      embarcada
                          ? Icons.directions_bus_filled_rounded
                          : Icons.airline_seat_individual_suite,
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
