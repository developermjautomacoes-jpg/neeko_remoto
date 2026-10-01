import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

// Home screen of the NEEKO "cliente" build (incoming-only).
const _kBg = Color(0xFF07110D);
const _kSidebar = Color(0xFF0A1511);
const _kCard = Color(0xFF0C1813);
const _kField = Color(0xFF0A1410);
const _kBorder = Color(0xFF1C2E24);
const _kGreen = Color(0xFF4ADE40);
const _kGreenLight = Color(0xFFA3F77B);
const _kGreenDark = Color(0xFF14532D);
const _kMuted = Color(0xFF9AA8A0);
const _kWarn = Color(0xFFF5B342);
const _kError = Color(0xFFEF5D5D);

const kNeekoHomeSize = Size(960, 580);

class NeekoHomeView extends StatefulWidget {
  const NeekoHomeView({Key? key}) : super(key: key);

  @override
  State<NeekoHomeView> createState() => _NeekoHomeViewState();
}

class _NeekoHomeViewState extends State<NeekoHomeView> {
  final RxBool _showPassword = false.obs;
  final Rx<SvcStatus> _status = SvcStatus.connecting.obs;
  final RxBool _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  Timer? _timer;
  String _hostname = '';

  @override
  void initState() {
    super.initState();
    try {
      _hostname = Platform.localHostname;
    } catch (_) {}
    _timer = periodic_immediate(const Duration(seconds: 1), _updateStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      imcomingOnlyHomeSize = kNeekoHomeSize;
      windowManager.setSize(getIncomingOnlyHomeSize());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    final status =
        jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
    final n = status['status_num'] as int;
    _status.value = n == 1
        ? SvcStatus.ready
        : (n == 0 ? SvcStatus.connecting : SvcStatus.notReady);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast('Copiado');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Container(
        color: _kBg,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CurvesPainter())),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildMainCard(context)),
                        const SizedBox(width: 20),
                        SizedBox(width: 260, child: _buildStatusCard()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 210,
      decoration: const BoxDecoration(
        color: _kSidebar,
        border: Border(right: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Image.asset('assets/logo_dark.png',
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('NEEKO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold))),
          ),
          _navItem(Icons.desktop_windows_outlined, 'Acesso Remoto',
              selected: true),
          if (!bind.isDisableSettings())
            _navItem(Icons.settings_outlined, 'Configurações',
                onTap: () => DesktopTabPage.onAddSetting()),
          _navItem(Icons.help_outline, 'Ajuda',
              onTap: () => _showHelp(context)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool selected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: selected ? _kGreen.withOpacity(0.06) : Colors.transparent,
          border: Border(
            left: BorderSide(
                color: selected ? _kGreen : Colors.transparent, width: 3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: selected ? _kGreenLight : _kMuted),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: selected ? Colors.white : _kMuted)),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Ajuda', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Passe o seu ID e a senha para o suporte técnico da Neeko.\n\n'
          'O acesso só acontece enquanto este programa estiver aberto '
          'e você pode encerrar a conexão a qualquer momento.',
          style: TextStyle(color: _kMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: _kGreen)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _kCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      );

  Widget _buildMainCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
      child: SingleChildScrollView(
        child: Consumer<ServerModel>(
          builder: (context, model, _) {
            final showOneTime = model.approveMode != 'click' &&
                model.verificationMethod != kUsePermanentPassword;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 28, height: 3, color: _kGreen),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    children: [
                      TextSpan(text: 'Permitir '),
                      TextSpan(
                          text: 'acesso remoto',
                          style: TextStyle(color: _kGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Compartilhe seu ID e senha com o suporte técnico para '
                  'que possamos acessar seu computador com segurança.',
                  style: TextStyle(fontSize: 14, color: _kMuted, height: 1.5),
                ),
                const SizedBox(height: 24),
                _buildIdField(model),
                const SizedBox(height: 14),
                _buildPasswordField(model, showOneTime),
                const SizedBox(height: 24),
                _buildActions(model, showOneTime),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fieldShell(
      {required IconData icon,
      required String label,
      required Widget value,
      required List<Widget> actions}) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kGreen, size: 26),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, letterSpacing: 1.2, color: _kMuted)),
                const SizedBox(height: 4),
                value,
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, String tooltip, VoidCallback onTap,
      {bool boxed = true}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 8),
          decoration: boxed
              ? BoxDecoration(
                  color: _kGreenDark.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGreen.withOpacity(0.35)),
                )
              : null,
          child: Icon(icon, size: 20, color: boxed ? _kGreen : _kMuted),
        ),
      ),
    );
  }

  Widget _buildIdField(ServerModel model) {
    return _fieldShell(
      icon: Icons.desktop_windows_outlined,
      label: 'SEU ID',
      value: ValueListenableBuilder<TextEditingValue>(
        valueListenable: model.serverId,
        builder: (_, v, __) => SelectableText(v.text,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 1)),
      ),
      actions: [
        _iconAction(Icons.copy_outlined, 'Copiar ID',
            () => _copy(model.serverId.id)),
      ],
    );
  }

  Widget _buildPasswordField(ServerModel model, bool showOneTime) {
    return _fieldShell(
      icon: Icons.lock_outline,
      label: 'SENHA',
      value: showOneTime
          ? ValueListenableBuilder<TextEditingValue>(
              valueListenable: model.serverPasswd,
              builder: (_, v, __) => Obx(() => Text(
                    _showPassword.value
                        ? v.text
                        : '•' * (v.text.isEmpty ? 6 : v.text.length),
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 1),
                  )),
            )
          : const Text('Senha definida pelo técnico',
              style: TextStyle(fontSize: 15, color: _kMuted)),
      actions: showOneTime
          ? [
              Obx(() => _iconAction(
                  _showPassword.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  _showPassword.value ? 'Ocultar senha' : 'Mostrar senha',
                  () => _showPassword.toggle(),
                  boxed: false)),
              _iconAction(Icons.refresh, 'Gerar nova senha',
                  () => bind.mainUpdateTemporaryPassword(),
                  boxed: false),
              _iconAction(Icons.copy_outlined, 'Copiar senha',
                  () => _copy(model.serverPasswd.text)),
            ]
          : [],
    );
  }

  Widget _buildActions(ServerModel model, bool showOneTime) {
    final installed = bind.mainIsInstalled();
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Obx(() {
            final stopped = _svcStopped.value;
            return _primaryButton(
              icon: Icons.link,
              label: stopped ? 'Permitir acesso remoto' : 'Copiar ID e senha',
              onTap: () {
                if (stopped) {
                  start_service(true);
                } else {
                  final pass = showOneTime ? model.serverPasswd.text : '';
                  _copy(pass.isEmpty
                      ? 'ID: ${model.serverId.id}'
                      : 'ID: ${model.serverId.id}\nSenha: $pass');
                }
              },
            );
          }),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _secondaryButton(
            icon: installed ? Icons.verified_user_outlined : Icons.shield_outlined,
            label: installed ? 'Privilégios elevados' : 'Elevar privilégios',
            tooltip: installed
                ? 'O programa está instalado e tem acesso completo.'
                : 'Instala o programa para permitir acesso completo, '
                    'inclusive em telas de administrador.',
            onTap: installed ? null : () => bind.mainGotoInstall(),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [_kGreenLight, _kGreen]),
          boxShadow: [
            BoxShadow(
                color: _kGreen.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF052E16), size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF052E16))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton(
      {required IconData icon,
      required String label,
      required String tooltip,
      VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: _kField,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? Colors.white : _kGreen, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.white : _kMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(26),
      child: Obx(() {
        final stopped = _svcStopped.value;
        final status = _status.value;
        final Color color;
        final String text;
        if (stopped) {
          color = _kError;
          text = 'Acesso desativado';
        } else if (status == SvcStatus.ready) {
          color = _kGreen;
          text = 'Pronto para conexão';
        } else if (status == SvcStatus.connecting) {
          color = _kWarn;
          text = 'Conectando...';
        } else {
          color = _kError;
          text = 'Sem conexão com o servidor';
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGreenDark.withOpacity(0.4),
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 44, color: _kGreenLight),
            ),
            const SizedBox(height: 20),
            const Text('Conexão segura',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Seus dados estão protegidos com criptografia.',
                style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: color.withOpacity(0.08),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(text,
                        style: TextStyle(fontSize: 13, color: color)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Divider(color: _kBorder, height: 1),
            const SizedBox(height: 18),
            Row(
              children: const [
                Icon(Icons.computer_outlined, size: 20, color: _kMuted),
                SizedBox(width: 12),
                Text('Seu computador',
                    style: TextStyle(fontSize: 13, color: _kMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_hostname.isEmpty ? '-' : _hostname.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white, letterSpacing: 0.5)),
          ],
        );
      }),
    );
  }
}

class _CurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final w = size.width;
    final h = size.height;
    paint.color = _kGreen.withOpacity(0.10);
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.78)
          ..quadraticBezierTo(w * 0.12, h * 0.62, w * 0.24, h * 0.66),
        paint);
    paint.color = _kGreen.withOpacity(0.18);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.62, h)
          ..quadraticBezierTo(w * 0.85, h * 0.9, w, h * 0.72),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.78, h)
          ..quadraticBezierTo(w * 0.9, h * 0.86, w, h * 0.82),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
