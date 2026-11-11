import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';

void main() {
  runApp(const CompressorApp());
}

// ======================================================
// APLICATIVO
// ======================================================

class CompressorApp extends StatelessWidget {
  const CompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle do Compressor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const CompressorHomePage(),
    );
  }
}

// ======================================================
// TELA PRINCIPAL
// ======================================================

class CompressorHomePage extends StatefulWidget {
  const CompressorHomePage({super.key});

  @override
  State<CompressorHomePage> createState() =>
      _CompressorHomePageState();
}

class _CompressorHomePageState
    extends State<CompressorHomePage> {
  bool compressorLigado = false;
  bool wifiConectado = false;

  void alternarCompressor() {
    setState(() {
      compressorLigado = !compressorLigado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          'Controle do Compressor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // ==================================================
            // STATUS
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                children: [

                  const Icon(
                    Icons.settings,
                    size: 60,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'COMPRESSOR',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color: compressorLigado
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(30),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Icon(
                          Icons.circle,
                          size: 15,
                          color: compressorLigado
                              ? Colors.green
                              : Colors.red,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          compressorLigado
                              ? 'LIGADO'
                              : 'DESLIGADO',

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: compressorLigado
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // BOTÃO LIGAR / DESLIGAR
            // ==================================================

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: alternarCompressor,

                icon: Icon(
                  compressorLigado
                      ? Icons.power_settings_new
                      : Icons.power,
                  size: 30,
                ),

                label: Text(
                  compressorLigado
                      ? 'DESLIGAR COMPRESSOR'
                      : 'LIGAR COMPRESSOR',

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: compressorLigado
                      ? Colors.red
                      : Colors.green,

                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // WIFI
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [

                  Icon(
                    Icons.wifi,
                    color: wifiConectado
                        ? Colors.green
                        : Colors.grey,
                    size: 30,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Conexão',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          wifiConectado
                              ? 'ESP32 conectada'
                              : 'ESP32 não conectada',

                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Switch(
                    value: wifiConectado,

                    onChanged: (valor) {
                      setState(() {
                        wifiConectado = valor;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // PROGRAMAÇÃO
            // ==================================================

            SizedBox(
              width: double.infinity,

              child: Card(
                elevation: 0,
                color: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(10),

                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFE3F2FD),

                    child: Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                    ),
                  ),

                  title: const Text(
                    'Programação',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: const Text(
                    'Definir horários de funcionamento',
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProgramacaoPage(),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Controle remoto do compressor',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TELA DE PROGRAMAÇÃO
// ======================================================

class ProgramacaoPage extends StatefulWidget {
  const ProgramacaoPage({super.key});

  @override
  State<ProgramacaoPage> createState() =>
      _ProgramacaoPageState();
}

class _ProgramacaoPageState
    extends State<ProgramacaoPage> {

  TimeOfDay horarioInicio = const TimeOfDay(
    hour: 8,
    minute: 0,
  );

  Duration tempoFuncionamento =
      const Duration(hours: 2);

  bool segunda = true;
  bool terca = true;
  bool quarta = true;
  bool quinta = true;
  bool sexta = true;
  bool sabado = false;
  bool domingo = false;

  bool naoFuncionarFeriados = true;

  bool carregando = true;

  // ======================================================
  // CHAVE DO ARMAZENAMENTO
  // ======================================================

  static const String chaveProgramacao =
      'programacao_compressor';

  // ======================================================
  // CARREGAR DADOS SALVOS
  // ======================================================

  @override
  void initState() {
    super.initState();

    carregarProgramacao();
  }

  void carregarProgramacao() {

    final String? dados =
        html.window.localStorage[chaveProgramacao];

    if (dados == null) {
      setState(() {
        carregando = false;
      });

      return;
    }

    try {

      final Map<String, dynamic> programacao =
          jsonDecode(dados);

      final int hora =
          programacao['hora'] ?? 8;

      final int minuto =
          programacao['minuto'] ?? 0;

      final int duracaoHoras =
          programacao['duracaoHoras'] ?? 2;

      final int duracaoMinutos =
          programacao['duracaoMinutos'] ?? 0;

      setState(() {

        horarioInicio = TimeOfDay(
          hour: hora,
          minute: minuto,
        );

        tempoFuncionamento = Duration(
          hours: duracaoHoras,
          minutes: duracaoMinutos,
        );

        segunda =
            programacao['segunda'] ?? true;

        terca =
            programacao['terca'] ?? true;

        quarta =
            programacao['quarta'] ?? true;

        quinta =
            programacao['quinta'] ?? true;

        sexta =
            programacao['sexta'] ?? true;

        sabado =
            programacao['sabado'] ?? false;

        domingo =
            programacao['domingo'] ?? false;

        naoFuncionarFeriados =
            programacao['feriados'] ?? true;

        carregando = false;
      });

    } catch (e) {

      setState(() {
        carregando = false;
      });

      debugPrint(
        'Erro ao carregar programação: $e',
      );
    }
  }

  // ======================================================
  // ESCOLHER HORÁRIO
  // ======================================================

  Future<void> escolherHorario() async {

    final TimeOfDay? horario =
        await showTimePicker(
      context: context,

      initialTime: horarioInicio,

      builder: (context, child) {

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),

          child: child!,
        );
      },
    );

    if (horario != null) {

      setState(() {
        horarioInicio = horario;
      });
    }
  }

  // ======================================================
  // ESCOLHER DURAÇÃO
  // ======================================================

  Future<void> escolherDuracao() async {

    int horas =
        tempoFuncionamento.inHours;

    int minutos =
        tempoFuncionamento.inMinutes % 60;

    await showDialog(
      context: context,

      builder: (context) {

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {

            return AlertDialog(

              title: const Text(
                'Tempo de funcionamento',
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  const Text(
                    'Defina por quanto tempo '
                    'o compressor ficará ligado.',
                  ),

                  const SizedBox(height: 25),

                  // HORAS

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      const Text(
                        'Horas:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 15),

                      DropdownButton<int>(
                        value: horas,

                        items: List.generate(
                          24,
                          (index) {

                            return DropdownMenuItem<int>(
                              value: index,

                              child: Text(
                                index
                                    .toString()
                                    .padLeft(2, '0'),
                              ),
                            );
                          },
                        ),

                        onChanged: (valor) {

                          if (valor != null) {

                            setDialogState(() {
                              horas = valor;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // MINUTOS

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      const Text(
                        'Minutos:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 15),

                      DropdownButton<int>(
                        value: minutos,

                        items: List.generate(
                          60,
                          (index) {

                            return DropdownMenuItem<int>(
                              value: index,

                              child: Text(
                                index
                                    .toString()
                                    .padLeft(2, '0'),
                              ),
                            );
                          },
                        ),

                        onChanged: (valor) {

                          if (valor != null) {

                            setDialogState(() {
                              minutos = valor;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '${horas}h ${minutos}min',

                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    'CANCELAR',
                  ),
                ),

                ElevatedButton(
                  onPressed: () {

                    setState(() {

                      tempoFuncionamento =
                          Duration(
                        hours: horas,
                        minutes: minutos,
                      );
                    });

                    Navigator.pop(context);
                  },

                  child: const Text(
                    'CONFIRMAR',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ======================================================
  // SALVAR PROGRAMAÇÃO
  // ======================================================

  void salvarProgramacao() {

    final Map<String, dynamic> programacao = {

      'hora': horarioInicio.hour,

      'minuto': horarioInicio.minute,

      'duracaoHoras':
          tempoFuncionamento.inHours,

      'duracaoMinutos':
          tempoFuncionamento.inMinutes % 60,

      'segunda': segunda,

      'terca': terca,

      'quarta': quarta,

      'quinta': quinta,

      'sexta': sexta,

      'sabado': sabado,

      'domingo': domingo,

      'feriados':
          naoFuncionarFeriados,
    };

    html.window.localStorage[
      chaveProgramacao
    ] = jsonEncode(programacao);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Programação salva com sucesso!',
        ),

        duration:
            Duration(seconds: 2),
      ),
    );
  }

  // ======================================================
  // TELA
  // ======================================================

  @override
  Widget build(BuildContext context) {

    if (carregando) {

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor:
          const Color(0xFFF4F6F8),

      appBar: AppBar(

        title: const Text(
          'Programação',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor:
            Colors.white,

        elevation: 0,
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            // ==================================================
            // HORÁRIO
            // ==================================================

            Card(
              color: Colors.white,

              child: ListTile(

                leading:
                    const CircleAvatar(
                  backgroundColor:
                      Color(0xFFE3F2FD),

                  child: Icon(
                    Icons.access_time,
                    color: Colors.blue,
                  ),
                ),

                title: const Text(
                  'Horário para ligar',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  horarioInicio.format(
                    context,
                  ),
                ),

                trailing:
                    const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),

                onTap:
                    escolherHorario,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // DURAÇÃO
            // ==================================================

            Card(
              color: Colors.white,

              child: ListTile(

                leading:
                    const CircleAvatar(
                  backgroundColor:
                      Color(0xFFE8F5E9),

                  child: Icon(
                    Icons.timer,
                    color: Colors.green,
                  ),
                ),

                title: const Text(
                  'Tempo de funcionamento',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  '${tempoFuncionamento.inHours}h '
                  '${tempoFuncionamento.inMinutes % 60}min',
                ),

                trailing:
                    const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),

                onTap:
                    escolherDuracao,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // DIAS
            // ==================================================

            const Align(
              alignment:
                  Alignment.centerLeft,

              child: Text(
                'Dias de funcionamento',

                style: TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Card(
              color: Colors.white,

              child: Column(
                children: [

                  CheckboxListTile(
                    title: const Text(
                      'Segunda-feira',
                    ),

                    value: segunda,

                    onChanged: (value) {

                      setState(() {
                        segunda =
                            value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Terça-feira',
                    ),

                    value: terca,

                    onChanged: (value) {

                      setState(() {
                        terca =
                            value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Quarta-feira',
                    ),

                    value: quarta,

                    onChanged: (value) {

                      setState(() {
                        quarta =
                            value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Quinta-feira',
                    ),

                    value: quinta,

                    onChanged: (value) {

                      setState(() {
                        quinta =
                            value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Sexta-feira',
                    ),

                    value: sexta,

                    onChanged: (value) {

                      setState(() {
                        sexta =
                            value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Sábado',
                    ),

                    value: sabado,

                    onChanged: (value) {

                      setState(() {
                        sabado =
                            value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Domingo',
                    ),

                    subtitle:
                        const Text(
                      'Desligado automaticamente',
                    ),

                    value: domingo,

                    onChanged: (value) {

                      setState(() {
                        domingo =
                            value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // FERIADOS
            // ==================================================

            Card(
              color: Colors.white,

              child: CheckboxListTile(

                title: const Text(
                  'Não funcionar em feriados',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                subtitle:
                    const Text(
                  'O compressor ficará '
                  'desligado automaticamente',
                ),

                value:
                    naoFuncionarFeriados,

                onChanged: (value) {

                  setState(() {

                    naoFuncionarFeriados =
                        value ?? true;
                  });
                },
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // SALVAR
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(

                onPressed:
                    salvarProgramacao,

                icon:
                    const Icon(
                  Icons.save,
                ),

                label:
                    const Text(
                  'SALVAR PROGRAMAÇÃO',

                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      Colors.blue,

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 18,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}