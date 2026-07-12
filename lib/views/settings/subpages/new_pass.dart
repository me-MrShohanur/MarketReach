import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketing/bloc/update-pass/repo/update_pass.dart';
import 'package:marketing/bloc/update-pass/update_pass_bloc.dart';
import 'dart:math' as math;

// ════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ════════════════════════════════════════════════════════════════════════════

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UpdatePasswordBloc(repository: UpdatePasswordRepository()),
      child: const _ChangePasswordBody(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BODY
// Fields (order matches API query params):
//   1. Username           → API: userName
//   2. Current Password   → API: currentPassword
//   3. New Password       → API: newPassword
// ════════════════════════════════════════════════════════════════════════════

class _ChangePasswordBody extends StatefulWidget {
  const _ChangePasswordBody();

  @override
  State<_ChangePasswordBody> createState() => _ChangePasswordBodyState();
}

class _ChangePasswordBodyState extends State<_ChangePasswordBody>
    with TickerProviderStateMixin {
  final _userNameCtrl = TextEditingController(); // → userName
  final _currentPassCtrl = TextEditingController(); // → currentPassword
  final _newPassCtrl = TextEditingController(); // → newPassword

  final _userNameFocus = FocusNode();
  final _currentPassFocus = FocusNode();
  final _newPassFocus = FocusNode();

  bool _showCurrentPass = false;
  bool _showNewPass = false;

  // ── Field-level server error tracking ──────────────────────────────────────
  String? _userNameError;
  String? _currentPassError;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _strengthCtrl;
  late final Animation<double> _strengthAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  double _strengthValue = 0.0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  // ── Validation ────────────────────────────────────────────────────────────
  bool get _canSubmit =>
      _userNameCtrl.text.isNotEmpty &&
      _currentPassCtrl.text.isNotEmpty &&
      _newPassCtrl.text.length >= 6;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _strengthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _strengthAnim = CurvedAnimation(
      parent: _strengthCtrl,
      curve: Curves.easeInOut,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _userNameCtrl.addListener(() => setState(() {}));
    _newPassCtrl.addListener(_onPasswordChanged);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entranceCtrl.forward(),
    );
  }

  void _onPasswordChanged() {
    final p = _newPassCtrl.text;
    double strength = 0;

    if (p.isEmpty) {
      strength = 0;
      _strengthLabel = '';
      _strengthColor = Colors.transparent;
    } else if (p.length < 6) {
      strength = 0.2;
      _strengthLabel = 'Too short';
      _strengthColor = Colors.redAccent;
    } else {
      if (p.length >= 8) strength += 0.25;
      if (p.contains(RegExp(r'[A-Z]'))) strength += 0.25;
      if (p.contains(RegExp(r'[0-9]'))) strength += 0.25;
      if (p.contains(RegExp(r'[!@#\$&*~%^]'))) strength += 0.25;

      if (strength <= 0.25) {
        _strengthLabel = 'Weak';
        _strengthColor = Colors.orangeAccent;
      } else if (strength <= 0.5) {
        _strengthLabel = 'Fair';
        _strengthColor = const Color(0xFFFFC107);
      } else if (strength <= 0.75) {
        _strengthLabel = 'Good';
        _strengthColor = const Color(0xFF4CAF50);
      } else {
        _strengthLabel = 'Strong';
        _strengthColor = const Color(0xFF00897B);
      }
    }

    setState(() => _strengthValue = strength);
    _strengthCtrl.animateTo(strength);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _strengthCtrl.dispose();
    _pulseCtrl.dispose();
    _userNameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _userNameFocus.dispose();
    _currentPassFocus.dispose();
    _newPassFocus.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit(BuildContext context) {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    context.read<UpdatePasswordBloc>().add(
      SubmitUpdatePassword(
        userName: _userNameCtrl.text.trim(), // → API
        currentPassword: _currentPassCtrl.text.trim(), // → API
        newPassword: _newPassCtrl.text.trim(), // → API
      ),
    );
  }

  // ── Snack helpers ──────────────────────────────────────────────────────────

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Password changed successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
    _userNameCtrl.clear();
    _currentPassCtrl.clear();
    _newPassCtrl.clear();
    setState(() {
      _strengthValue = 0;
      _strengthLabel = '';
      _userNameError = null;
      _currentPassError = null;
    });
    _strengthCtrl.animateTo(0);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdatePasswordBloc, UpdatePasswordState>(
      listener: (context, state) {
        if (state is UpdatePasswordSuccess) {
          _showSuccess();
          context.read<UpdatePasswordBloc>().add(ResetUpdatePassword());
        } else if (state is UpdatePasswordFailure) {
          setState(() {
            _userNameError = null;
            _currentPassError = null;
            final msg = state.message.toLowerCase();
            if (msg.contains('username')) {
              _userNameError = state.message;
            } else if (msg.contains('current password') ||
                msg.contains('password is incorrect')) {
              _currentPassError = state.message;
            }
          });
          _showError(state.message);
          context.read<UpdatePasswordBloc>().add(ResetUpdatePassword());
        } else if (state is UpdatePasswordError) {
          final msg = state.message.contains('Unauthorized')
              ? 'Session expired. Please log in again.'
              : 'Failed to update password. Please try again.';
          _showError(msg);
          context.read<UpdatePasswordBloc>().add(ResetUpdatePassword());
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          children: [
                            // ── Hero ──────────────────────────────────────
                            _buildHeroIllustration(),

                            const SizedBox(height: 28),

                            // ── Field 1: Username ──────────────────────────
                            _buildUserNameField(),

                            const SizedBox(height: 14),

                            // ── Field 2: Current Password ─────────────────
                            _buildCurrentPasswordField(),

                            const SizedBox(height: 14),

                            // ── Field 3: New Password ─────────────────────
                            _buildNewPasswordField(),

                            // Strength indicator
                            if (_newPassCtrl.text.isNotEmpty)
                              _buildStrengthRow(),

                            const SizedBox(height: 28),

                            // ── Submit ─────────────────────────────────────
                            _buildSubmitButton(context),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHeroIllustration() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _strengthAnim,
            builder: (_, _) => CustomPaint(
              painter: _StrengthRingPainter(
                progress: _strengthAnim.value,
                color: _strengthValue == 0
                    ? const Color(0xFFE0E0E0)
                    : _strengthColor,
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _strengthValue == 0
                      ? const Color(0xFFF5F5F5)
                      : _strengthColor.withValues(alpha: 0.08),
                ),
                child: Icon(
                  _strengthValue >= 0.75
                      ? Icons.lock_rounded
                      : Icons.lock_outline_rounded,
                  size: 36,
                  color: _strengthValue == 0 ? Colors.black26 : _strengthColor,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _strengthLabel.isEmpty
                  ? const Text(
                      'Set a strong password',
                      key: ValueKey('default'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Container(
                      key: ValueKey(_strengthLabel),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _strengthColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _strengthColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _strengthLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _strengthColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field 1: Username ────────────────────────────────────────────────────────

  Widget _buildUserNameField() {
    final hasError = _userNameError != null;
    final accent = hasError ? Colors.redAccent : const Color(0xFF00897B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: hasError
                    ? Text(
                        key: ValueKey(_userNameError),
                        _userNameError!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: accent, width: 3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.person_outline_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _userNameCtrl,
                  focusNode: _userNameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _currentPassFocus.requestFocus(),
                  onChanged: (_) {
                    setState(() => _userNameError = null);
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter username',
                    hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Field 2: Current Password ───────────────────────────────────────────────

  Widget _buildCurrentPasswordField() {
    final hasError = _currentPassError != null;
    final accent = hasError ? Colors.redAccent : const Color(0xFF9C27B0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Password',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: hasError
                    ? Text(
                        key: ValueKey(_currentPassError),
                        _currentPassError!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: accent, width: 3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasError ? Icons.error_outline_rounded : Icons.key_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _currentPassCtrl,
                  focusNode: _currentPassFocus,
                  obscureText: !_showCurrentPass,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _newPassFocus.requestFocus(),
                  onChanged: (_) {
                    setState(() => _currentPassError = null);
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter current password',
                    hintStyle: const TextStyle(
                      color: Colors.black26,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _showCurrentPass = !_showCurrentPass),
                      child: Icon(
                        _showCurrentPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Field 3: New Password ───────────────────────────────────────────────────

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'New Password',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: _strengthValue == 0
                    ? const Color(0xFF2196F3)
                    : _strengthColor,
                width: 3,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        (_strengthValue == 0
                                ? const Color(0xFF2196F3)
                                : _strengthColor)
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: _strengthValue == 0
                        ? const Color(0xFF2196F3)
                        : _strengthColor,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _newPassCtrl,
                  focusNode: _newPassFocus,
                  obscureText: !_showNewPass,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(context),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Min 6 characters',
                    hintStyle: const TextStyle(
                      color: Colors.black26,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _showNewPass = !_showNewPass),
                      child: Icon(
                        _showNewPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Strength row ────────────────────────────────────────────────────────────

  Widget _buildStrengthRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (i) {
              final filled = _strengthValue >= (i + 1) * 0.25;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? _strengthColor : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _req('8+ chars', _newPassCtrl.text.length >= 8),
              const SizedBox(width: 6),
              _req('A-Z', _newPassCtrl.text.contains(RegExp(r'[A-Z]'))),
              const SizedBox(width: 6),
              _req('0-9', _newPassCtrl.text.contains(RegExp(r'[0-9]'))),
              const SizedBox(width: 6),
              _req('!@#', _newPassCtrl.text.contains(RegExp(r'[!@#\$&*~%^]'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _req(String label, bool met) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: met
          ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
          : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: met
            ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
            : Colors.transparent,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
          size: 10,
          color: met ? const Color(0xFF4CAF50) : Colors.black26,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: met ? const Color(0xFF4CAF50) : Colors.black38,
          ),
        ),
      ],
    ),
  );

  // ── Submit button ───────────────────────────────────────────────────────────

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<UpdatePasswordBloc, UpdatePasswordState>(
      builder: (context, state) {
        final isLoading = state is UpdatePasswordLoading;
        final canTap = _canSubmit && !isLoading;

        return AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, _) => Transform.scale(
            scale: canTap ? _pulseAnim.value : 1.0,
            child: GestureDetector(
              onTap: canTap ? () => _submit(context) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: canTap ? Colors.black : Colors.black26,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: canTap
                      ? const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STRENGTH RING PAINTER
// ════════════════════════════════════════════════════════════════════════════

class _StrengthRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _StrengthRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrengthRingPainter old) =>
      old.progress != progress || old.color != color;
}
