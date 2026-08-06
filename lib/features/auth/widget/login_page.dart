import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final emailCtl = useTextEditingController();
    final passwordCtl = useTextEditingController();
    final showPassword = useState(false);
    final isRegisterMode = useState(false);

    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (prev, next) {
      if (next case AsyncData(value: true)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/home');
        });
      } else if (next case AsyncError(:final error)) {
        final msg = error.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    });

    final isBusy = authState.isLoading;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xff0a1c3a),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0a1c3a).withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded, size: 56, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'VukaVPN',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      isRegisterMode.value ? '创建账号 · 一键翻墙' : '登录你的账号 · 一键翻墙',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isBusy,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtl,
                    obscureText: !showPassword.value,
                    enabled: !isBusy,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: '密码 (至少 8 位)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(showPassword.value ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => showPassword.value = !showPassword.value,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              final email = emailCtl.text.trim();
                              final pw = passwordCtl.text;
                              if (email.isEmpty || !email.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入正确的邮箱')),
                                );
                                return;
                              }
                              if (pw.length < 8) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('密码至少 8 位')),
                                );
                                return;
                              }
                              final notifier = ref.read(authNotifierProvider.notifier);
                              if (isRegisterMode.value) {
                                notifier.register(email: email, password: pw);
                              } else {
                                notifier.login(email, pw);
                              }
                            },
                      child: isBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isRegisterMode.value ? '注册并登录' : '登录',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isRegisterMode.value ? '已有账号？' : '还没有账号？'),
                      TextButton(
                        onPressed: isBusy ? null : () => isRegisterMode.value = !isRegisterMode.value,
                        child: Text(isRegisterMode.value ? '去登录' : '去注册'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '登录即视为同意《服务条款》与《隐私政策》',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
