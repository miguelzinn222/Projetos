import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CompressorApp());
}

// ============================================================
// APLICATIVO
// ============================================================

class CompressorApp extends StatelessWidget {
  const CompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle do Compressor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// LOGIN E CONTROLE DE ACESSO
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) return const LoginPage();
        return const CompressorHomePage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  bool criandoConta = false;
  bool processando = false;
  bool ocultarSenha = true;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void mensagem(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> autenticar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;
    if (email.isEmpty || senha.isEmpty) {
      mensagem('Preencha o e-mail e a senha.');
      return;
    }
    if (senha.length < 6) {
      mensagem('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }
    setState(() => processando = true);
    try {
      if (criandoConta) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: senha);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: senha);
      }
    } on FirebaseAuthException catch (e) {
      const textos = <String, String>{
        'email-already-in-use': 'Este e-mail já possui uma conta. Entre nela.',
        'invalid-email': 'O formato do e-mail é inválido.',
        'weak-password': 'Escolha uma senha mais forte.',
        'user-not-found': 'Conta não encontrada. Crie uma conta primeiro.',
        'wrong-password': 'Senha incorreta.',
        'invalid-credential': 'E-mail ou senha incorretos.',
        'network-request-failed': 'Sem conexão com a internet.',
        'too-many-requests': 'Muitas tentativas. Aguarde e tente novamente.',
        'operation-not-allowed': 'Ative E-mail/senha em Firebase Authentication.',
      };
      mensagem(textos[e.code] ?? 'Não foi possível entrar: ${e.message ?? e.code}');
    } catch (e) {
      mensagem('Erro ao acessar a conta: $e');
    } finally {
      if (mounted) setState(() => processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.settings_input_component, size: 52, color: Color(0xFF102A43)),
                    const SizedBox(height: 12),
                    const Text('Controle do Compressor', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(criandoConta ? 'Crie sua conta para sincronizar a programação.' :
                      'Entre para acessar sua programação sincronizada.', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextField(controller: emailController, keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 14),
                    TextField(controller: senhaController, obscureText: ocultarSenha,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) { if (!processando) autenticar(); },
                      decoration: InputDecoration(labelText: 'Senha (mínimo 6 caracteres)',
                        border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => ocultarSenha = !ocultarSenha),
                          icon: Icon(ocultarSenha ? Icons.visibility : Icons.visibility_off)))),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: processando ? null : autenticar,
                      child: processando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(criandoConta ? 'Criar conta' : 'Entrar')),
                    TextButton(onPressed: processando ? null : () => setState(() => criandoConta = !criandoConta),
                      child: Text(criandoConta ? 'Já tenho uma conta — entrar' : 'Não tenho conta — criar conta')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TELA PRINCIPAL
// ============================================================

class CompressorHomePage extends StatefulWidget {
  const CompressorHomePage({super.key});

  @override
  State<CompressorHomePage> createState() => _CompressorHomePageState();
}

class _CompressorHomePageState extends State<CompressorHomePage> {
  // ==========================================================
  // ESTADOS
  // ==========================================================

  bool compressorLigado = false;

  // Comunicação com o ESP32-S3
  // Altere este endereço quando o ESP32 estiver na rede.
  String enderecoESP32 = 'http://10.0.0.2';
  bool wifiConectado = false;
  bool conectandoWifi = false;
  Timer? timerStatusESP32;

  // Emergência:
  // No sistema real, esse valor virá do ESP32.
  // NÃO existe botão virtual de emergência.
  bool emergenciaAtiva = false;

  // Impede vários comandos ao mesmo tempo.
  bool comandoEmExecucao = false;

  // ==========================================================
  // COMUNICAÇÃO COM O ESP32-S3
  // ==========================================================

  Future<Map<String, dynamic>?> consultarStatusESP32() async {
    try {
      final resposta = await html.HttpRequest.getString(
        '$enderecoESP32/status',
      );

      final dados = jsonDecode(resposta);

      if (dados is! Map) return null;

      return Map<String, dynamic>.from(dados);
    } catch (_) {
      return null;
    }
  }

  Future<void> atualizarStatusESP32() async {
    final dados = await consultarStatusESP32();

    if (!mounted) return;

    if (dados == null) {
      if (wifiConectado && !comandoEmExecucao) {
        setState(() {
          wifiConectado = false;
          compressorLigado = false;
        });
      }
      return;
    }

    setState(() {
      wifiConectado = true;

      if (dados['compressor'] is bool) {
        compressorLigado = dados['compressor'];
      }

      if (dados['emergencia'] is bool) {
        emergenciaAtiva = dados['emergencia'];
      }
    });
  }

  void iniciarAtualizacaoDeStatus() {
    timerStatusESP32?.cancel();

    timerStatusESP32 = Timer.periodic(
      const Duration(seconds: 2),
      (_) => atualizarStatusESP32(),
    );
  }

  Future<void> conectarESP32() async {
    if (conectandoWifi) return;

    setState(() {
      conectandoWifi = true;
      wifiConectado = false;
    });

    final dados = await consultarStatusESP32();

    if (!mounted) return;

    if (dados == null) {
      setState(() {
        conectandoWifi = false;
        wifiConectado = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível conectar ao ESP32. Verifique o IP e a rede Wi-Fi.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      conectandoWifi = false;
      wifiConectado = true;

      if (dados['compressor'] is bool) {
        compressorLigado = dados['compressor'];
      }

      if (dados['emergencia'] is bool) {
        emergenciaAtiva = dados['emergencia'];
      }
    });

    iniciarAtualizacaoDeStatus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ESP32 conectado.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // DESCONEXÃO
  // ==========================================================

  void desconectarESP32() {
    if (comandoEmExecucao) return;

    timerStatusESP32?.cancel();
    timerStatusESP32 = null;

    setState(() {
      wifiConectado = false;
      compressorLigado = false;
      emergenciaAtiva = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ESP32 desconectado.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // LIGAR / DESLIGAR COMPRESSOR
  // ==========================================================

  Future<void> alternarCompressor() async {
    if (comandoEmExecucao) return;
    if (!wifiConectado) return;
    if (emergenciaAtiva) return;

    setState(() {
      comandoEmExecucao = true;
    });

    final bool ligar = !compressorLigado;

    try {
      final resposta = await html.HttpRequest.request(
        '$enderecoESP32/${ligar ? 'ligar' : 'desligar'}',
        method: 'GET',
      );

      if (!mounted) return;

      if (resposta.status == 200) {
        final dados = await consultarStatusESP32();

        if (dados != null) {
          setState(() {
            if (dados['compressor'] is bool) {
              compressorLigado = dados['compressor'];
            }

            if (dados['emergencia'] is bool) {
              emergenciaAtiva = dados['emergencia'];
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                compressorLigado
                    ? 'Compressor ligado.'
                    : 'Compressor desligado.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            wifiConectado = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ESP32 recusou o comando. Código: ${resposta.status}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        wifiConectado = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha na comunicação com o ESP32.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          comandoEmExecucao = false;
        });
      }
    }
  }

  @override
  void dispose() {
    timerStatusESP32?.cancel();
    super.dispose();
  }

  // ==========================================================
  // FUNÇÃO AUXILIAR
  // ==========================================================

  Color corEstadoCompressor() {
    if (compressorLigado) {
      return Colors.green;
    }

    return Colors.grey;
  }

  // ==========================================================
  // INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool bloqueado =
        !wifiConectado || conectandoWifi || comandoEmExecucao || emergenciaAtiva;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 22,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controle do Compressor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Painel de controle',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 18, top: 13, bottom: 13),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, size: 14, color: Colors.orangeAccent),
                SizedBox(width: 5),
                Text(
                  'ESP32',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: () async {
              timerStatusESP32?.cancel();
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // PAINEL PRINCIPAL
                // ==================================================
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'COMPRESSOR',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7C93),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: compressorLigado
                              ? const Color(0xFFE8F7EE)
                              : const Color(0xFFF0F3F6),
                          border: Border.all(
                            color: compressorLigado
                                ? Colors.green
                                : const Color(0xFFD5DDE5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          compressorLigado
                              ? Icons.power
                              : Icons.power_settings_new,
                          size: 52,
                          color: compressorLigado
                              ? Colors.green
                              : const Color(0xFF7B8794),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        compressorLigado ? 'LIGADO' : 'DESLIGADO',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: compressorLigado
                              ? Colors.green.shade700
                              : const Color(0xFF52606D),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        comandoEmExecucao
                            ? 'Processando comando...'
                            : wifiConectado
                                ? 'Sistema pronto para comando manual'
                                : 'Conecte o ESP32 para liberar o comando',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8291A1),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: bloqueado ? null : alternarCompressor,
                          icon: comandoEmExecucao
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  compressorLigado
                                      ? Icons.power_settings_new
                                      : Icons.power,
                                ),
                          label: Text(
                            comandoEmExecucao
                                ? 'PROCESSANDO...'
                                : compressorLigado
                                    ? 'DESLIGAR COMPRESSOR'
                                    : 'LIGAR COMPRESSOR',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: compressorLigado
                                ? const Color(0xFFD64545)
                                : const Color(0xFF168A55),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFD6DCE2),
                            disabledForegroundColor: const Color(0xFF8793A0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // STATUS DE CONEXÃO E EMERGÊNCIA
                // ==================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _statusCard(
                        icon: Icons.wifi,
                        title: 'ESP32',
                        value: conectandoWifi
                            ? 'Conectando...'
                            : wifiConectado
                                ? 'Conectada'
                                : 'Desconectada',
                        color: conectandoWifi
                            ? Colors.orange
                            : wifiConectado
                                ? Colors.green
                                : const Color(0xFF7B8794),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statusCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'EMERGÊNCIA',
                        value: emergenciaAtiva ? 'ATIVADA' : 'Normal',
                        color: emergenciaAtiva
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ==================================================
                // CONTROLE DA CONEXÃO
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE1E7ED),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (wifiConectado
                                  ? Colors.green
                                  : const Color(0xFF607D8B))
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          wifiConectado
                              ? Icons.router
                              : Icons.router_outlined,
                          color: wifiConectado
                              ? Colors.green
                              : const Color(0xFF607D8B),
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comunicação',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Conexão com o controlador ESP32',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8291A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: conectandoWifi
                            ? null
                            : wifiConectado
                                ? desconectarESP32
                                : conectarESP32,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F5D8F),
                          side: const BorderSide(
                            color: Color(0xFF1F5D8F),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          conectandoWifi
                              ? 'CONECTANDO'
                              : wifiConectado
                                  ? 'DESCONECTAR'
                                  : 'CONECTAR',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PROGRAMAÇÃO
                // ==================================================
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgramacaoPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE1E7ED),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F5D8F).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF1F5D8F),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Programação',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Horários, dias e datas sem produção',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8291A1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 17,
                            color: Color(0xFF9AA6B2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // AVISO DISCRETO DE TESTE
                // ==================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD58A),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 18,
                        color: Color(0xFFB7791F),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Comunicação Wi-Fi com o ESP32 preparada.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A641B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                const Center(
                  child: Text(
                    'Controle do Compressor',
                    style: TextStyle(
                      color: Color(0xFF9AA6B2),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1E7ED),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8291A1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TELA DE PROGRAMAÇÃO
// ============================================================

class ProgramacaoPage extends StatefulWidget {
  const ProgramacaoPage({super.key});

  @override
  State<ProgramacaoPage> createState() => _ProgramacaoPageState();
}

class _ProgramacaoPageState extends State<ProgramacaoPage> {
  // ==========================================================
  // HORÁRIO
  // ==========================================================

  TimeOfDay horarioInicio =
      const TimeOfDay(hour: 8, minute: 0);

  Duration tempoFuncionamento =
      const Duration(hours: 2);

  // ==========================================================
  // DIAS DA SEMANA
  // ==========================================================

  bool segunda = true;
  bool terca = true;
  bool quarta = true;
  bool quinta = true;
  bool sexta = true;
  bool sabado = false;
  bool domingo = false;

  // ==========================================================
  // FERIADOS
  // ==========================================================

  bool naoFuncionarFeriados = true;

  // ==========================================================
  // DATAS SEM PRODUÇÃO
  // ==========================================================

  List<DateTime> datasSemProducao = [];

  bool carregando = true;

  // ==========================================================
  // CHAVE DO LOCAL STORAGE
  // ==========================================================

  static const String chaveProgramacao =
      'programacao_compressor';

  // ==========================================================
  // INICIALIZAÇÃO
  // ==========================================================

  @override
  void initState() {
    super.initState();

    carregarProgramacao();
  }

  // ==========================================================
  // CARREGAR PROGRAMAÇÃO
  // ==========================================================

  Future<void> carregarProgramacao() async {
    Map<String, dynamic>? programacao;

    // Primeiro tenta buscar a programação da conta na nuvem.
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario != null) {
        final documento = await FirebaseFirestore.instance
            .collection('usuarios').doc(usuario.uid)
            .collection('configuracoes').doc('programacao_compressor').get();
        if (documento.exists) programacao = documento.data();
      }
    } catch (_) {
      // Se a nuvem falhar, tenta recuperar o backup local.
    }

    // Se ainda não houver documento na nuvem, usa a cópia local.
    if (programacao == null) {
      try {
        final dados = html.window.localStorage[chaveProgramacao];
        if (dados != null && dados.isNotEmpty) {
          programacao = Map<String, dynamic>.from(jsonDecode(dados));
        }
      } catch (_) {}
    }

    if (programacao != null && mounted) {
      setState(() {
        horarioInicio = TimeOfDay(
          hour: (programacao!['hora'] as num?)?.toInt() ?? 8,
          minute: (programacao['minuto'] as num?)?.toInt() ?? 0,
        );
        tempoFuncionamento = Duration(
          hours: (programacao['duracaoHoras'] as num?)?.toInt() ?? 2,
          minutes: (programacao['duracaoMinutos'] as num?)?.toInt() ?? 0,
        );
        segunda = programacao['segunda'] as bool? ?? true;
        terca = programacao['terca'] as bool? ?? true;
        quarta = programacao['quarta'] as bool? ?? true;
        quinta = programacao['quinta'] as bool? ?? true;
        sexta = programacao['sexta'] as bool? ?? true;
        sabado = programacao['sabado'] as bool? ?? false;
        domingo = programacao['domingo'] as bool? ?? false;
        naoFuncionarFeriados = programacao['feriados'] as bool? ?? true;
        final datas = programacao['datasSemProducao'] as List<dynamic>? ?? [];
        datasSemProducao = datas
            .map((data) => DateTime.tryParse(data.toString()))
            .whereType<DateTime>().toList();
      });
    }

    // Mantém o backup local e migra-o para a nuvem se não houver documento.
    if (programacao != null) {
      try {
        html.window.localStorage[chaveProgramacao] = jsonEncode(programacao);
      } catch (_) {}
      try {
        final usuario = FirebaseAuth.instance.currentUser;
        if (usuario != null) {
          final ref = FirebaseFirestore.instance.collection('usuarios').doc(usuario.uid)
              .collection('configuracoes').doc('programacao_compressor');
          final doc = await ref.get();
          if (!doc.exists) await ref.set(programacao);
        }
      } catch (_) {
        // A programação segue disponível no backup local.
      }
    }

    if (mounted) setState(() => carregando = false);
  }

  // ==========================================================
  // ESCOLHER HORÁRIO
  // ==========================================================

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

  // ==========================================================
  // ESCOLHER DURAÇÃO
  // ==========================================================

  Future<void> escolherDuracao() async {
    int horas = tempoFuncionamento.inHours;

    int minutos =
        tempoFuncionamento.inMinutes % 60;

    await showDialog(
      context: context,
      builder: (context) {
        int horasSelecionadas = horas;
        int minutosSelecionados = minutos;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Tempo de funcionamento',
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: horasSelecionadas,
                    decoration: const InputDecoration(
                      labelText: 'Horas',
                    ),
                    items: List.generate(
                      24,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('$index hora(s)'),
                      ),
                    ),
                    onChanged: (valor) {
                      if (valor == null) return;

                      setDialogState(() {
                        horasSelecionadas = valor;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<int>(
                    value: minutosSelecionados,
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                    ),
                    items: List.generate(
                      60,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('$index minuto(s)'),
                      ),
                    ),
                    onChanged: (valor) {
                      if (valor == null) return;

                      setDialogState(() {
                        minutosSelecionados = valor;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCELAR'),
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      tempoFuncionamento =
                          Duration(
                        hours: horasSelecionadas,
                        minutes: minutosSelecionados,
                      );
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // ADICIONAR DATA SEM PRODUÇÃO
  // ==========================================================

  Future<void> adicionarDataParada() async {
    final DateTime agora = DateTime.now();

    final DateTime? data =
        await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: DateTime(agora.year),
      lastDate: DateTime(agora.year + 10),
    );

    if (data == null) return;

    final DateTime dataNormalizada =
        DateTime(
      data.year,
      data.month,
      data.day,
    );

    final bool jaExiste =
        datasSemProducao.any(
      (item) =>
          item.year == dataNormalizada.year &&
          item.month == dataNormalizada.month &&
          item.day == dataNormalizada.day,
    );

    if (jaExiste) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Essa data já está cadastrada.',
          ),
        ),
      );

      return;
    }

    setState(() {
      datasSemProducao.add(dataNormalizada);
    });

    datasSemProducao.sort();
  }

  // ==========================================================
  // REMOVER DATA
  // ==========================================================

  void removerDataParada(int index) {
    setState(() {
      datasSemProducao.removeAt(index);
    });
  }

  // ==========================================================
  // SALVAR PROGRAMAÇÃO
  // ==========================================================

  Future<void> salvarProgramacao() async {
    final Map<String, dynamic> programacao = {
      'hora': horarioInicio.hour,
      'minuto': horarioInicio.minute,
      'duracaoHoras': tempoFuncionamento.inHours,
      'duracaoMinutos': tempoFuncionamento.inMinutes % 60,
      'segunda': segunda,
      'terca': terca,
      'quarta': quarta,
      'quinta': quinta,
      'sexta': sexta,
      'sabado': sabado,
      'domingo': domingo,
      'feriados': naoFuncionarFeriados,
      'datasSemProducao': datasSemProducao
          .map((data) => data.toIso8601String().split('T').first).toList(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    // Backup local primeiro, para preservar a programação se a internet falhar.
    try {
      final backup = Map<String, dynamic>.from(programacao)..remove('atualizadoEm');
      html.window.localStorage[chaveProgramacao] = jsonEncode(backup);
    } catch (_) {}

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) throw Exception('Sua sessão expirou. Entre novamente.');
      await FirebaseFirestore.instance.collection('usuarios').doc(usuario.uid)
          .collection('configuracoes').doc('programacao_compressor')
          .set(programacao, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Programação salva na nuvem e no backup local.'),
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup local salvo, mas a nuvem falhou: $e'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String formatarData(DateTime data) {
    final String dia =
        data.day.toString().padLeft(2, '0');

    final String mes =
        data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // ==========================================================
  // FORMATAR HORÁRIO
  // ==========================================================

  String formatarHorario(TimeOfDay horario) {
    final String hora =
        horario.hour.toString().padLeft(2, '0');

    final String minuto =
        horario.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  // ==========================================================
  // FORMATAR DURAÇÃO
  // ==========================================================

  String formatarDuracao(Duration duracao) {
    final int horas = duracao.inHours;

    final int minutos =
        duracao.inMinutes % 60;

    if (horas == 0 && minutos == 0) {
      return '0 minutos';
    }

    if (horas == 0) {
      return '$minutos minuto(s)';
    }

    if (minutos == 0) {
      return '$horas hora(s)';
    }

    return '$horas hora(s) e $minutos minuto(s)';
  }

  // ==========================================================
  // CHECKBOX DE DIA
  // ==========================================================

  Widget checkboxDia(
    String nome,
    bool valor,
    ValueChanged<bool?> aoMudar,
  ) {
    return CheckboxListTile(
      title: Text(nome),
      value: valor,
      onChanged: aoMudar,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity:
          ListTileControlAffinity.leading,
    );
  }

  // ==========================================================
  // INTERFACE DA PROGRAMAÇÃO
  // ==========================================================

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
      appBar: AppBar(
        title: const Text(
          'Programação',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==================================================
            // HORÁRIO PARA LIGAR
            // ==================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: Colors.blue,
                ),

                title: const Text(
                  'Horário para ligar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  formatarHorario(horarioInicio),
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),

                onTap: escolherHorario,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // TEMPO DE FUNCIONAMENTO
            // ==================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.timer,
                  color: Colors.blue,
                ),

                title: const Text(
                  'Tempo de funcionamento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  formatarDuracao(
                    tempoFuncionamento,
                  ),
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),

                onTap: escolherDuracao,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DIAS DA SEMANA
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dias de funcionamento',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    checkboxDia(
                      'Segunda-feira',
                      segunda,
                      (valor) {
                        setState(() {
                          segunda = valor ?? false;
                        });
                      },
                    ),

                    checkboxDia(
                      'Terça-feira',
                      terca,
                      (valor) {
                        setState(() {
                          terca = valor ?? false;
                        });
                      },
                    ),

                    checkboxDia(
                      'Quarta-feira',
                      quarta,
                      (valor) {
                        setState(() {
                          quarta = valor ?? false;
                        });
                      },
                    ),

                    checkboxDia(
                      'Quinta-feira',
                      quinta,
                      (valor) {
                        setState(() {
                          quinta = valor ?? false;
                        });
                      },
                    ),

                    checkboxDia(
                      'Sexta-feira',
                      sexta,
                      (valor) {
                        setState(() {
                          sexta = valor ?? false;
                        });
                      },
                    ),

                    checkboxDia(
                      'Sábado',
                      sabado,
                      (valor) {
                        setState(() {
                          sabado = valor ?? false;
                        });
                      },
                    ),

                    checkboxDia(
                      'Domingo',
                      domingo,
                      (valor) {
                        setState(() {
                          domingo = valor ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // FERIADOS
            // ==================================================

            Card(
              child: CheckboxListTile(
                title: const Text(
                  'Não funcionar em feriados',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  'Impede o funcionamento programado '
                  'em dias de feriado.',
                ),

                value: naoFuncionarFeriados,

                onChanged: (valor) {
                  setState(() {
                    naoFuncionarFeriados =
                        valor ?? false;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DATAS SEM PRODUÇÃO
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datas sem produção',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Nessas datas o compressor não deverá '
                      'funcionar pela programação.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (datasSemProducao.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        child: Center(
                          child: Text(
                            'Nenhuma data cadastrada.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                    if (datasSemProducao.isNotEmpty)
                      Column(
                        children: List.generate(
                          datasSemProducao.length,
                          (index) {
                            final data =
                                datasSemProducao[index];

                            return ListTile(
                              contentPadding:
                                  EdgeInsets.zero,

                              leading: const Icon(
                                Icons.event_busy,
                                color: Colors.red,
                              ),

                              title: Text(
                                formatarData(data),
                              ),

                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  removerDataParada(
                                    index,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: adicionarDataParada,
                        icon: const Icon(
                          Icons.add,
                        ),
                        label: const Text(
                          'ADICIONAR DATA',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SALVAR
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: salvarProgramacao,
                icon: const Icon(
                  Icons.save,
                ),
                label: const Text(
                  'SALVAR PROGRAMAÇÃO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}