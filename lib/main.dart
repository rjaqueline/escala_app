// Imports organizados
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'proximo_mes_page.dart'; // tela de próximo mês

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeDateFormatting('pt_BR', null);

  // Configuração de Notificações
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const EscalaApp());
}

class EscalaApp extends StatelessWidget {
  const EscalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MINHA ESCALA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorSchemeSeed: const Color(0xFF483D8B),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF483D8B),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF483D8B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      home: const EscalaHome(),
    );
  }
}

class EscalaHome extends StatefulWidget {
  const EscalaHome({super.key});

  @override
  State<EscalaHome> createState() => _EscalaHomeState();
}

class _EscalaHomeState extends State<EscalaHome> {
  // ---------- ESTADO DA TELA ----------
  DateTime? dataBase;
  String status = "";
  int diasRestantes = 0;
  String turmaSelecionada = "1A";
  String proximaMudancaTexto = "";

  // deslocamento dentro do ciclo
  static final Map<String, int> turmasDeslocamento = {
    "1A": 0,
    "1B": 2,
    "1C": 5,
    "1D": 7,
    "2A": 10,
    "2B": 12,
    "2C": 15,
    "2D": 17,
  };

  // Datas base reais de 2024 para cada turma
  static final Map<String, DateTime> datasBaseEscalas2024 = {
    "1B": DateTime(2024, 1, 3),
    "2B": DateTime(2024, 1, 5),
    "1D": DateTime(2024, 1, 8),
    "2D": DateTime(2024, 1, 10),
    "1A": DateTime(2024, 1, 13),
    "2A": DateTime(2024, 1, 15),
    "1C": DateTime(2024, 1, 18),
    "2C": DateTime(2024, 1, 20),
  };

  // Lista fixa de turmas
  static const List<String> turmas = [
    "1A",
    "1B",
    "1C",
    "1D",
    "2A",
    "2B",
    "2C",
    "2D",
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _mostrarAvisos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // permite maior altura
      backgroundColor: Colors.transparent, // deixa flutuante
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.55, // 🌟 modal mais alto e centralizado
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Avisos Importantes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 🔹 Aviso 1
                Row(
                  children: const [
                    Icon(Icons.warning, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Antes de realizar qualquer viagem, confirme sua escala no sistema oficial.",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔹 Aviso 2
                Row(
                  children: const [
                    Icon(Icons.lock_person_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Não compartilhe sua escala com desconhecidos. Evite riscos de furtos durante sua viagem.",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- LÓGICA DE DADOS (PERSISTÊNCIA) ----------
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Carrega só a turma salva (se tiver), senão usa 1A

    final turma = prefs.getString('turma') ?? '1A';

    setState(() {
      turmaSelecionada = turma;
      // dataBase vem SEMPRE da tabela fixa de 2024
      dataBase = datasBaseEscalas2024[turmaSelecionada];
      _calcularStatus();
    });
  }

  // ---------- LÓGICA DE INTERAÇÃO ----------
  void _onTurmaChanged(String? value) async {
    if (value != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('turma', value);

      setState(() {
        turmaSelecionada = value;
        dataBase = datasBaseEscalas2024[turmaSelecionada];
        _calcularStatus();
      });

      await scheduleNextTravelNotification(
        dataBase!,
        turmasDeslocamento[turmaSelecionada]!,
      );
    }
  }

  void _atualizarStatusManual() {
    setState(() {
      _calcularStatus();
    });
  }

  // ---------- LÓGICA DE NEGÓCIO ----------

  void _calcularStatus() {
    if (dataBase == null) return;

    // Data de hoje sem horário
    final agora = DateTime.now();
    final hojeLimpo = DateTime(agora.year, agora.month, agora.day);

    // A data-base REAL da turma (ex: 03/01/2024 para 1B)
    final base = dataBase!;
    final baseLimpa = DateTime(base.year, base.month, base.day);

    // Dias desde o primeiro embarque real daquela turma
    final dias = hojeLimpo.difference(baseLimpa).inDays;

    // Ciclo de 0 a 19 (12 embarcada + 8 folga)
    final ciclo = ((dias % 20) + 20) % 20;

    late DateTime proximaMudanca;

    if (ciclo < 12) {
      // 0 a 11 -> embarcada (incluindo dias de viagem)
      status = "Embarcada";
      diasRestantes = 12 - ciclo;

      // Próximo desembarque (último dia embarcada: viagem de volta)
      proximaMudanca = hojeLimpo.add(Duration(days: diasRestantes - 1));
    } else {
      // 12 a 19 -> folga
      status = "De folga";
      diasRestantes = 20 - ciclo;

      // Próximo embarque (volta pra mina)
      proximaMudanca = hojeLimpo.add(Duration(days: diasRestantes));
    }

    final df = DateFormat('dd/MM/yyyy');
    proximaMudancaTexto = (status == "Embarcada")
        ? "Próximo desembarque: ${df.format(proximaMudanca)}"
        : "Próximo embarque: ${df.format(proximaMudanca)}";
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isEmbarcada = status == "Embarcada";

    return Scaffold(
      appBar: AppBar(title: const Text("Minha Escala")),
      drawer: _buildMenuDrawer(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Selecione sua turma",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.info_rounded,
                    size: 28,
                    color: Color(0xFF483D8B),
                  ),
                  onPressed: _mostrarAvisos,
                ),
              ),

              Wrap(spacing: 8, runSpacing: 8, children: _buildTurmaButtons()),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(double.infinity, 40),
                  ),

                  onPressed: _atualizarStatusManual,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text("Atualizar Status"),
                ),
              ),

              const SizedBox(height: 10),

              _buildStatusCard(isEmbarcada),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTurmaButtons() {
    return turmas.map((t) {
      final selecionada = (turmaSelecionada == t);

      return SizedBox(
        width: 70, // menor e mais elegante
        height: 42, // altura ajustada também
        child: ElevatedButton(
          onPressed: () => _onTurmaChanged(t),
          style: ElevatedButton.styleFrom(
            backgroundColor: selecionada
                ? const Color(0xFF483D8B)
                : Colors.white,
            foregroundColor: selecionada
                ? Colors.white
                : const Color(0xFF483D8B),
            side: const BorderSide(color: Color(0xFF483D8B), width: 1.2),
          ),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }).toList();
  }

  Widget _buildStatusCard(bool isEmbarcada) {
    // --- CORES CERTAS PARA CADA ESTADO ---
    final Color statusColor = isEmbarcada
        ? Colors
              .red
              .shade700 // Embarcada = vermelho
        : Colors.green.shade700; // Folga = verde

    final Color backgroundColor = isEmbarcada
        ? Colors
              .red
              .shade50 // Fundo vermelho claro
        : Colors.green.shade50; // Fundo verde claro

    final IconData statusIcon = isEmbarcada
        ? Icons
              .directions_bus_filled_rounded // Ônibus animado
        : Icons.airline_seat_individual_suite; // Rede (descanso)

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LINHA COM ÍCONE E STATUS ---
          Row(
            children: [
              AnimatedSlide(
                duration: const Duration(milliseconds: 600),
                offset: isEmbarcada ? const Offset(0.15, 0) : Offset.zero,
                curve: Curves.easeInOut,
                child: AnimatedRotation(
                  turns: isEmbarcada ? 0.02 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: Icon(statusIcon, color: statusColor, size: 40),
                ),
              ),
              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status atual:",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      status,
                      key: ValueKey(status),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            "Dias até próxima mudança: $diasRestantes",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            proximaMudancaTexto,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF483D8B)),
            child: Text(
              "Menu",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text("Próximo mês"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProximoMesPage(escala: turmaSelecionada),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------- NOTIFICAÇÕES EXTERNAS ----------
Future<void> scheduleNextTravelNotification(
  DateTime dataBase,
  int deslocamento,
) async {
  final now = DateTime.now();

  for (int i = 0; i < 30; i++) {
    final candidate = DateTime(now.year, now.month, now.day + i);

    final diasDesde = candidate
        .difference(DateTime(dataBase.year, dataBase.month, dataBase.day))
        .inDays;

    final ciclo = ((diasDesde + deslocamento) % 20 + 20) % 20;

    if (ciclo == 0 || ciclo == 11) {
      final notificationDay = candidate.subtract(const Duration(days: 1));

      final scheduled = DateTime(
        notificationDay.year,
        notificationDay.month,
        notificationDay.day,
        8,
        0,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Viagem amanhã',
        'Amanhã é dia de viagem. Prepare-se!',
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'escala_channel',
            'Escala 12x8',
            channelDescription: 'Notificações de viagem',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      break;
    }
  }
}
