# Auth Pages Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 3 card-based auth page styles (login/register/forgot-password) under the Design TAB for preview/selection.

**Architecture:** A new `AuthDesignPage` container hosts a SegmentedButton (style switcher) + TabBar (page type switcher). Each style is a separate StatefulWidget containing 3 sub-pages. All pages are preview-only — buttons show a SnackBar, no real API calls. Shared UI helpers (logo header, password strength bar, step indicator) are extracted into small widget files to avoid duplication.

**Tech Stack:** Flutter/Dart, existing AppColors + AppTheme constants

---

## File Map

| File | Responsibility |
|------|---------------|
| `app/lib/pages/design/auth_design_page.dart` | Main container: SegmentedButton style switcher + TabBar page switcher |
| `app/lib/pages/design/auth_common_widgets.dart` | Shared widgets: `AuthLogoHeader`, `PasswordStrengthBar`, `StepIndicator`, `DesignPreviewButton`, `designSnackBar` |
| `app/lib/pages/design/auth_style_a/login_page_a.dart` | Style A login |
| `app/lib/pages/design/auth_style_a/register_page_a.dart` | Style A register |
| `app/lib/pages/design/auth_style_a/forgot_password_page_a.dart` | Style A forgot password |
| `app/lib/pages/design/auth_style_a/auth_style_a_page.dart` | Style A container (TabBar with 3 sub-pages) |
| `app/lib/pages/design/auth_style_b/login_page_b.dart` | Style B login |
| `app/lib/pages/design/auth_style_b/register_page_b.dart` | Style B register |
| `app/lib/pages/design/auth_style_b/forgot_password_page_b.dart` | Style B forgot password |
| `app/lib/pages/design/auth_style_b/auth_style_b_page.dart` | Style B container |
| `app/lib/pages/design/auth_style_c/login_page_c.dart` | Style C login |
| `app/lib/pages/design/auth_style_c/register_page_c.dart` | Style C register |
| `app/lib/pages/design/auth_style_c/forgot_password_page_c.dart` | Style C forgot password |
| `app/lib/pages/design/auth_style_c/auth_style_c_page.dart` | Style C container |
| `app/lib/pages/design_page.dart` | Modified: button 3 → "认证页面设计" |

---

### Task 1: Create shared auth design widgets

**Files:**
- Create: `app/lib/pages/design/auth_common_widgets.dart`

- [ ] **Step 1: Create `auth_common_widgets.dart` with all shared widgets**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';

/// Logo + app name header used by all auth design pages
class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.grid_view,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '小方格',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Password strength indicator bar (red/orange/green 3-segment)
class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    if (password.length < 8) return 1;
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) return 1;
    if (password.length >= 10 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return 3;
    }
    return 2;
  }

  Color get _color {
    switch (_strength) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.success;
      default:
        return AppColors.divider;
    }
  }

  String get _label {
    switch (_strength) {
      case 1:
        return '弱';
      case 2:
        return '中';
      case 3:
        return '强';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < _strength ? _color : AppColors.divider,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }),
        ),
        if (_strength > 0) ...[
          const SizedBox(height: 4),
          Text(
            '密码强度：$_label',
            style: TextStyle(color: _color, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Step indicator for forgot-password flow (①→②→③)
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final step = index + 1;
        final isCompleted = step < currentStep;
        final isCurrent = step == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              if (index < totalSteps - 1)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '$step',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent ? Colors.white : AppColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Primary action button for design preview pages
class DesignPreviewButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const DesignPreviewButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed ?? () => showDesignSnackBar(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// Show design preview SnackBar
void showDesignSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('此为设计预览，请选择您喜欢的风格'),
      duration: Duration(seconds: 2),
    ),
  );
}

/// Light-blue filled input decoration (Style A & C)
InputDecoration lightBlueInputDecoration({
  required IconData prefixIcon,
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.primaryLight.withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
  );
}

/// Label + divider input decoration (Style B)
class LabelDividerField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const LabelDividerField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ),
        Container(height: 1, color: AppColors.divider),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/pages/design/auth_common_widgets.dart
git commit -m "feat: add shared auth design widgets (logo, strength bar, step indicator, buttons)"
```

---

### Task 2: Create AuthDesignPage container

**Files:**
- Create: `app/lib/pages/design/auth_design_page.dart`

- [ ] **Step 1: Create `auth_design_page.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import 'auth_style_a/auth_style_a_page.dart';
import 'auth_style_b/auth_style_b_page.dart';
import 'auth_style_c/auth_style_c_page.dart';

class AuthDesignPage extends StatefulWidget {
  const AuthDesignPage({super.key});

  @override
  State<AuthDesignPage> createState() => _AuthDesignPageState();
}

class _AuthDesignPageState extends State<AuthDesignPage>
    with SingleTickerProviderStateMixin {
  int _selectedStyle = 0;
  late TabController _tabController;

  final _stylePages = const [
    AuthStyleAPage(),
    AuthStyleBPage(),
    AuthStyleCPage(),
  ];

  final _styleLabels = ['风格A', '风格B', '风格C'];
  final _styleDescriptions = ['经典居中卡片', '标签分割线卡片', '分段卡片组合'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('认证页面设计'),
      ),
      body: Column(
        children: [
          // Style selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<int>(
              segments: List.generate(
                3,
                (i) => ButtonSegment<int>(
                  value: i,
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_styleLabels[i]),
                      Text(
                        _styleDescriptions[i],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              selected: {_selectedStyle},
              onSelectionChanged: (selected) {
                setState(() => _selectedStyle = selected.first);
              },
            ),
          ),

          // Page type tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: '登录'),
                Tab(text: '注册'),
                Tab(text: '忘记密码'),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: IndexedStack(
              index: _selectedStyle,
              children: _stylePages,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/pages/design/auth_design_page.dart
git commit -m "feat: add AuthDesignPage container with style and tab switchers"
```

---

### Task 3: Create Style A pages

**Files:**
- Create: `app/lib/pages/design/auth_style_a/auth_style_a_page.dart`
- Create: `app/lib/pages/design/auth_style_a/login_page_a.dart`
- Create: `app/lib/pages/design/auth_style_a/register_page_a.dart`
- Create: `app/lib/pages/design/auth_style_a/forgot_password_page_a.dart`

- [ ] **Step 1: Create `auth_style_a_page.dart` container**

```dart
import 'package:flutter/material.dart';
import 'login_page_a.dart';
import 'register_page_a.dart';
import 'forgot_password_page_a.dart';

class AuthStyleAPage extends StatelessWidget {
  const AuthStyleAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LoginPageA(),
        RegisterPageA(),
        ForgotPasswordPageA(),
      ],
    );
  }
}
```

- [ ] **Step 2: Create `login_page_a.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class LoginPageA extends StatefulWidget {
  const LoginPageA({super.key});

  @override
  State<LoginPageA> createState() => _LoginPageAState();
}

class _LoginPageAState extends State<LoginPageA> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: lightBlueInputDecoration(
                    prefixIcon: Icons.phone,
                    hintText: '请输入手机号',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: lightBlueInputDecoration(
                    prefixIcon: Icons.lock,
                    hintText: '请输入密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => showDesignSnackBar(context),
                    child: const Text(
                      '忘记密码？',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const DesignPreviewButton(text: '登 录'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showDesignSnackBar(context),
            child: const Text(
              '还没有账号？去注册',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `register_page_a.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class RegisterPageA extends StatefulWidget {
  const RegisterPageA({super.key});

  @override
  State<RegisterPageA> createState() => _RegisterPageAState();
}

class _RegisterPageAState extends State<RegisterPageA> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: lightBlueInputDecoration(
                    prefixIcon: Icons.phone,
                    hintText: '请输入手机号',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: lightBlueInputDecoration(
                    prefixIcon: Icons.lock,
                    hintText: '至少8位，包含字母和数字',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                PasswordStrengthBar(password: _passwordController.text),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: lightBlueInputDecoration(
                    prefixIcon: Icons.lock_outline,
                    hintText: '再次输入密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nicknameController,
                  decoration: lightBlueInputDecoration(
                    prefixIcon: Icons.person_outline,
                    hintText: '选填',
                  ),
                ),
                const SizedBox(height: 20),
                const DesignPreviewButton(text: '注 册'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showDesignSnackBar(context),
            child: const Text(
              '已有账号？去登录',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create `forgot_password_page_a.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class ForgotPasswordPageA extends StatefulWidget {
  const ForgotPasswordPageA({super.key});

  @override
  State<ForgotPasswordPageA> createState() => _ForgotPasswordPageAState();
}

class _ForgotPasswordPageAState extends State<ForgotPasswordPageA> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 1;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                StepIndicator(currentStep: _currentStep),
                const SizedBox(height: 24),
                if (_currentStep == 1) ..._buildStep1(),
                if (_currentStep == 2) ..._buildStep2(),
                if (_currentStep == 3) ..._buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStep1() {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: lightBlueInputDecoration(
                prefixIcon: Icons.phone,
                hintText: '请输入手机号',
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('发送验证码'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, letterSpacing: 8),
        decoration: lightBlueInputDecoration(
          prefixIcon: Icons.verified_user,
          hintText: '6位验证码',
        ),
      ),
      const SizedBox(height: 16),
      DesignPreviewButton(
        text: '下一步',
        onPressed: () => setState(() => _currentStep = 3),
      ),
    ];
  }

  List<Widget> _buildStep3() {
    return [
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() {}),
        decoration: lightBlueInputDecoration(
          prefixIcon: Icons.lock,
          hintText: '至少8位，包含字母和数字',
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 6),
      PasswordStrengthBar(password: _passwordController.text),
      const SizedBox(height: 12),
      TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: lightBlueInputDecoration(
          prefixIcon: Icons.lock_outline,
          hintText: '再次输入密码',
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textTertiary,
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
      ),
      const SizedBox(height: 20),
      DesignPreviewButton(
        text: '完成',
        onPressed: () {
          setState(() => _currentStep = 1);
          showDesignSnackBar(context);
        },
      ),
    ];
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add app/lib/pages/design/auth_style_a/
git commit -m "feat: add Style A auth design pages (classic centered card)"
```

---

### Task 4: Create Style B pages

**Files:**
- Create: `app/lib/pages/design/auth_style_b/auth_style_b_page.dart`
- Create: `app/lib/pages/design/auth_style_b/login_page_b.dart`
- Create: `app/lib/pages/design/auth_style_b/register_page_b.dart`
- Create: `app/lib/pages/design/auth_style_b/forgot_password_page_b.dart`

- [ ] **Step 1: Create `auth_style_b_page.dart` container**

```dart
import 'package:flutter/material.dart';
import 'login_page_b.dart';
import 'register_page_b.dart';
import 'forgot_password_page_b.dart';

class AuthStyleBPage extends StatelessWidget {
  const AuthStyleBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LoginPageB(),
        RegisterPageB(),
        ForgotPasswordPageB(),
      ],
    );
  }
}
```

- [ ] **Step 2: Create `login_page_b.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class LoginPageB extends StatefulWidget {
  const LoginPageB({super.key});

  @override
  State<LoginPageB> createState() => _LoginPageBState();
}

class _LoginPageBState extends State<LoginPageB> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelDividerField(
                  label: '手机号',
                  hintText: '请输入手机号',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                LabelDividerField(
                  label: '密码',
                  hintText: '请输入密码',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => showDesignSnackBar(context),
                    child: const Text(
                      '忘记密码？',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const DesignPreviewButton(text: '登 录'),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => showDesignSnackBar(context),
                    child: const Text(
                      '还没有账号？去注册',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
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
```

- [ ] **Step 3: Create `register_page_b.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class RegisterPageB extends StatefulWidget {
  const RegisterPageB({super.key});

  @override
  State<RegisterPageB> createState() => _RegisterPageBState();
}

class _RegisterPageBState extends State<RegisterPageB> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelDividerField(
                  label: '手机号',
                  hintText: '请输入手机号',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                LabelDividerField(
                  label: '密码',
                  hintText: '至少8位，包含字母和数字',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 6),
                PasswordStrengthBar(password: _passwordController.text),
                const SizedBox(height: 16),
                LabelDividerField(
                  label: '确认密码',
                  hintText: '再次输入密码',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 16),
                LabelDividerField(
                  label: '昵称（选填）',
                  hintText: '请输入昵称',
                  controller: _nicknameController,
                ),
                const SizedBox(height: 20),
                const DesignPreviewButton(text: '注 册'),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => showDesignSnackBar(context),
                    child: const Text(
                      '已有账号？去登录',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
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
```

- [ ] **Step 4: Create `forgot_password_page_b.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class ForgotPasswordPageB extends StatefulWidget {
  const ForgotPasswordPageB({super.key});

  @override
  State<ForgotPasswordPageB> createState() => _ForgotPasswordPageBState();
}

class _ForgotPasswordPageBState extends State<ForgotPasswordPageB> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 1;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepIndicator(currentStep: _currentStep),
                const SizedBox(height: 24),
                if (_currentStep == 1) ..._buildStep1(),
                if (_currentStep == 2) ..._buildStep2(),
                if (_currentStep == 3) ..._buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStep1() {
    return [
      LabelDividerField(
        label: '手机号',
        hintText: '请输入手机号',
        controller: _phoneController,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      DesignPreviewButton(
        text: '发送验证码',
        onPressed: () => setState(() => _currentStep = 2),
      ),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      LabelDividerField(
        label: '验证码',
        hintText: '请输入6位验证码',
        controller: _codeController,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      DesignPreviewButton(
        text: '下一步',
        onPressed: () => setState(() => _currentStep = 3),
      ),
    ];
  }

  List<Widget> _buildStep3() {
    return [
      LabelDividerField(
        label: '新密码',
        hintText: '至少8位，包含字母和数字',
        controller: _passwordController,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() {}),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textTertiary,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 6),
      PasswordStrengthBar(password: _passwordController.text),
      const SizedBox(height: 16),
      LabelDividerField(
        label: '确认密码',
        hintText: '再次输入密码',
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textTertiary,
            size: 20,
          ),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      const SizedBox(height: 20),
      DesignPreviewButton(
        text: '完成',
        onPressed: () {
          setState(() => _currentStep = 1);
          showDesignSnackBar(context);
        },
      ),
    ];
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add app/lib/pages/design/auth_style_b/
git commit -m "feat: add Style B auth design pages (label + divider card)"
```

---

### Task 5: Create Style C pages

**Files:**
- Create: `app/lib/pages/design/auth_style_c/auth_style_c_page.dart`
- Create: `app/lib/pages/design/auth_style_c/login_page_c.dart`
- Create: `app/lib/pages/design/auth_style_c/register_page_c.dart`
- Create: `app/lib/pages/design/auth_style_c/forgot_password_page_c.dart`

- [ ] **Step 1: Create `auth_style_c_page.dart` container**

```dart
import 'package:flutter/material.dart';
import 'login_page_c.dart';
import 'register_page_c.dart';
import 'forgot_password_page_c.dart';

class AuthStyleCPage extends StatelessWidget {
  const AuthStyleCPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        LoginPageC(),
        RegisterPageC(),
        ForgotPasswordPageC(),
      ],
    );
  }
}
```

- [ ] **Step 2: Create `login_page_c.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class LoginPageC extends StatefulWidget {
  const LoginPageC({super.key});

  @override
  State<LoginPageC> createState() => _LoginPageCState();
}

class _LoginPageCState extends State<LoginPageC> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          // Card 1: Input area
          _buildCard(
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: lightBlueInputDecoration(
                  prefixIcon: Icons.phone,
                  hintText: '请输入手机号',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: lightBlueInputDecoration(
                  prefixIcon: Icons.lock,
                  hintText: '请输入密码',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Card 2: Action area
          _buildCard(
            children: const [
              DesignPreviewButton(text: '登 录'),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showDesignSnackBar(context),
            child: const Text(
              '忘记密码？',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => showDesignSnackBar(context),
            child: const Text(
              '还没有账号？去注册',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `register_page_c.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class RegisterPageC extends StatefulWidget {
  const RegisterPageC({super.key});

  @override
  State<RegisterPageC> createState() => _RegisterPageCState();
}

class _RegisterPageCState extends State<RegisterPageC> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          // Card 1: Input area
          _buildCard(
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: lightBlueInputDecoration(
                  prefixIcon: Icons.phone,
                  hintText: '请输入手机号',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                decoration: lightBlueInputDecoration(
                  prefixIcon: Icons.lock,
                  hintText: '至少8位，包含字母和数字',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              PasswordStrengthBar(password: _passwordController.text),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: lightBlueInputDecoration(
                  prefixIcon: Icons.lock_outline,
                  hintText: '再次输入密码',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nicknameController,
                decoration: lightBlueInputDecoration(
                  prefixIcon: Icons.person_outline,
                  hintText: '选填',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Card 2: Action area
          _buildCard(
            children: const [
              DesignPreviewButton(text: '注 册'),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showDesignSnackBar(context),
            child: const Text(
              '已有账号？去登录',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create `forgot_password_page_c.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import '../auth_common_widgets.dart';

class ForgotPasswordPageC extends StatefulWidget {
  const ForgotPasswordPageC({super.key});

  @override
  State<ForgotPasswordPageC> createState() => _ForgotPasswordPageCState();
}

class _ForgotPasswordPageCState extends State<ForgotPasswordPageC> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 1;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const AuthLogoHeader(),
          const SizedBox(height: 32),
          // Card 1: Step indicator
          _buildCard(
            children: [
              StepIndicator(currentStep: _currentStep),
            ],
          ),
          const SizedBox(height: 8),
          // Card 2: Content area
          _buildCard(
            children: [
              if (_currentStep == 1) ..._buildStep1(),
              if (_currentStep == 2) ..._buildStep2(),
              if (_currentStep == 3) ..._buildStep3(),
            ],
          ),
          const SizedBox(height: 8),
          // Card 3: Action area
          _buildCard(
            children: [
              if (_currentStep == 1)
                DesignPreviewButton(
                  text: '下一步',
                  onPressed: () => setState(() => _currentStep = 2),
                ),
              if (_currentStep == 2)
                DesignPreviewButton(
                  text: '下一步',
                  onPressed: () => setState(() => _currentStep = 3),
                ),
              if (_currentStep == 3)
                DesignPreviewButton(
                  text: '完成',
                  onPressed: () {
                    setState(() => _currentStep = 1);
                    showDesignSnackBar(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showDesignSnackBar(context),
            child: const Text(
              '返回登录',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStep1() {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: lightBlueInputDecoration(
                prefixIcon: Icons.phone,
                hintText: '请输入手机号',
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('发送验证码'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, letterSpacing: 8),
        decoration: lightBlueInputDecoration(
          prefixIcon: Icons.verified_user,
          hintText: '6位验证码',
        ),
      ),
    ];
  }

  List<Widget> _buildStep3() {
    return [
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() {}),
        decoration: lightBlueInputDecoration(
          prefixIcon: Icons.lock,
          hintText: '至少8位，包含字母和数字',
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 6),
      PasswordStrengthBar(password: _passwordController.text),
      const SizedBox(height: 12),
      TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: lightBlueInputDecoration(
          prefixIcon: Icons.lock_outline,
          hintText: '再次输入密码',
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textTertiary,
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
      ),
    ];
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add app/lib/pages/design/auth_style_c/
git commit -m "feat: add Style C auth design pages (segmented card combination)"
```

---

### Task 6: Wire up Design TAB button 3

**Files:**
- Modify: `app/lib/pages/design_page.dart`

- [ ] **Step 1: Update design_page.dart — change button 3 to navigate to AuthDesignPage**

Replace the 3rd `_buildMenuItem` call (lines 41-47) with:

```dart
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: '认证页面设计',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthDesignPage(),
                ),
              );
            },
          ),
```

And add the import at the top:

```dart
import 'design/auth_design_page.dart';
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/pages/design_page.dart
git commit -m "feat: wire up Design TAB button 3 to AuthDesignPage"
```

---

### Task 7: Verify build compiles

- [ ] **Step 1: Run Flutter analyze**

```bash
cd app && flutter analyze
```

Expected: No errors. Warnings are acceptable but should be noted.

- [ ] **Step 2: Fix any compilation errors if found**

If `flutter analyze` reports errors, fix them and re-run. Common issues:
- Missing imports
- Wrong file paths in imports
- Type mismatches

- [ ] **Step 3: Final commit if fixes were needed**

```bash
git add -A && git commit -m "fix: resolve compilation issues in auth design pages"
```
