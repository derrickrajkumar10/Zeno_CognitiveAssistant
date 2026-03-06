import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/mochi_widget.dart';

// ─── Shared helpers ────────────────────────────────────────────────────────────

/// Full-width black pill CTA button (design system: height 56, borderRadius 50).
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryButton,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: AppTheme.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Welcome Page ─────────────────────────────────────────────────────────────

class WelcomePage extends StatefulWidget {
  final VoidCallback onNext;
  const WelcomePage({required this.onNext, super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundOnboardingWelcome,
      child: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 60,
              right: 24,
              child: Transform.rotate(
                angle: 0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('✨', style: TextStyle(fontSize: 26)),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: -8,
                  duration: 2000.ms,
                  curve: Curves.easeInOut),
            ),
            Positioned(
              top: 140,
              left: 16,
              child: Transform.rotate(
                angle: -0.25,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🧠', style: TextStyle(fontSize: 24)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 600.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: 120,
              right: 20,
              child: Transform.rotate(
                angle: 0.35,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 28)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 1200.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        children: [
                          // Mochi
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppTheme.selectedGreen
                                  .withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                                child:
                                    MochiWidget(size: 140, interactive: false)),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Meet ZENO',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 44,
                              color: AppTheme.textPrimary,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your AI companion that quietly watches\nyour cognitive wellness — and keeps\nyou thriving.',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _PillButton(label: "Let's go >", onPressed: widget.onNext),
                  const SizedBox(height: 12),
                  Text(
                    'No account needed · Always private',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Name Entry Page ──────────────────────────────────────────────────────────

class NameEntryPage extends StatefulWidget {
  final VoidCallback onNext;
  final ValueChanged<String> onNameChanged;
  const NameEntryPage(
      {required this.onNext, required this.onNameChanged, super.key});

  @override
  State<NameEntryPage> createState() => _NameEntryPageState();
}

class _NameEntryPageState extends State<NameEntryPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundOnboardingFeature,
      child: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 60,
              right: 20,
              child: Transform.rotate(
                angle: 0.15,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('💬', style: TextStyle(fontSize: 24)),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: -8,
                  duration: 2000.ms,
                  curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: 140,
              left: 24,
              child: Transform.rotate(
                angle: -0.3,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌱', style: TextStyle(fontSize: 26)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 600.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),
            Positioned(
              top: 200,
              left: 14,
              child: Transform.rotate(
                angle: 0.4,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('✨', style: TextStyle(fontSize: 22)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 1200.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Mochi peeking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.selectedGreen.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                            child: MochiWidget(size: 56, interactive: false)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What should\nMochi call you?',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 38,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is just between you and Mochi.',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Name display
                  Center(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _ctrl,
                      builder: (_, val, __) {
                        final name =
                            val.text.isNotEmpty ? val.text : 'Your name…';
                        return Text(
                          name,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: val.text.isNotEmpty
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your name…',
                      hintStyle: GoogleFonts.nunito(
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: AppTheme.cardSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppTheme.selectedGreen, width: 1.5),
                      ),
                    ),
                    onChanged: widget.onNameChanged,
                    onSubmitted: (_) => widget.onNext(),
                  ),
                  const Spacer(),
                  _PillButton(label: 'Continue >', onPressed: widget.onNext),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Selection Page ────────────────────────────────────────────────────

class AvatarSelectionPage extends StatefulWidget {
  final ValueChanged<String> onCompanionSelected;
  const AvatarSelectionPage({required this.onCompanionSelected, super.key});

  static const _avatars = [
    _AvatarOption(
      id: 'mochi',
      emoji: '🐻',
      name: 'Mochi',
      locked: false,
      unlock: '',
      tagline: 'Your cozy bear cub bestie',
      description: 'Mochi is warm, calm and always in your corner.',
      color: Color(0xFFA78BFA),
    ),
    _AvatarOption(
      id: 'luna',
      emoji: '🦊',
      name: 'Luna',
      locked: true,
      unlock: 'Reach Level 5',
      tagline: 'The clever night fox',
      description: 'Luna is sharp-witted and full of late-night wisdom.',
      color: Color(0xFFFF8C42),
    ),
    _AvatarOption(
      id: 'kai',
      emoji: '🐼',
      name: 'Kai',
      locked: true,
      unlock: '7-day streak',
      tagline: 'The chill panda philosopher',
      description: 'Kai reminds you that rest is productive.',
      color: Color(0xFF34C77B),
    ),
    _AvatarOption(
      id: 'nova',
      emoji: '🐺',
      name: 'Nova',
      locked: true,
      unlock: '30-day streak',
      tagline: 'The fierce lone wolf',
      description: 'Nova pushes you past limits you didn\'t know you had.',
      color: Color(0xFF6EAAFF),
    ),
    _AvatarOption(
      id: 'zara',
      emoji: '🦁',
      name: 'Zara',
      locked: true,
      unlock: 'Level 10',
      tagline: 'The bold golden lion',
      description: 'Zara radiates confidence and celebrates every win.',
      color: Color(0xFFF9C74F),
    ),
  ];

  @override
  State<AvatarSelectionPage> createState() => _AvatarSelectionPageState();
}

class _AvatarSelectionPageState extends State<AvatarSelectionPage> {
  String _selected = 'mochi';

  void _onSelect(String id, bool locked) {
    if (locked) return;
    HapticFeedback.lightImpact();
    setState(() => _selected = id);
    widget.onCompanionSelected(id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundOnboardingPet,
      child: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 50,
              right: 18,
              child: Transform.rotate(
                angle: 0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🐾', style: TextStyle(fontSize: 26)),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: -8,
                  duration: 2000.ms,
                  curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: 120,
              left: 20,
              child: Transform.rotate(
                angle: -0.3,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 28)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 600.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),
            Positioned(
              top: 200,
              left: 12,
              child: Transform.rotate(
                angle: 0.4,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('✨', style: TextStyle(fontSize: 22)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 1200.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your\ncompanion',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 38,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Others unlock as you grow.',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                    itemCount: AvatarSelectionPage._avatars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final av = AvatarSelectionPage._avatars[i];
                      final isSelected = _selected == av.id;
                      return _TapScaleWrapper(
                        onTap: () => _onSelect(av.id, av.locked),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.selectedGreenTint
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.selectedGreen
                                  : av.locked
                                      ? const Color(0xFFE8E5F0)
                                      : const Color(0xFFE0DCF0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(av.emoji,
                                  style: TextStyle(
                                    fontSize: 26,
                                    color: av.locked
                                        ? AppTheme.textSecondary
                                            .withValues(alpha: 0.4)
                                        : null,
                                  )),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      av.name,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: av.locked
                                            ? AppTheme.textSecondary
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      av.locked
                                          ? 'Unlocks: ${av.unlock}'
                                          : av.tagline,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (av.locked)
                                const Icon(Icons.lock_rounded,
                                    size: 16, color: AppTheme.textSecondary)
                              else if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.selectedGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white),
                                )
                              else
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFD0CDE0),
                                        width: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: (i * 60).ms)
                          .fadeIn(duration: 350.ms)
                          .slideX(
                              begin: 0.12,
                              end: 0,
                              duration: 350.ms,
                              curve: Curves.easeOutCubic);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
                  child: _PillButton(
                    label: 'Continue >',
                    onPressed: () => widget.onCompanionSelected(_selected),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permissions Page ─────────────────────────────────────────────────────────

class PermissionsPage extends StatelessWidget {
  final VoidCallback onNext;
  const PermissionsPage({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundOnboardingReminders,
      child: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 50,
              right: 20,
              child: Transform.rotate(
                angle: 0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🛡️', style: TextStyle(fontSize: 26)),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: -8,
                  duration: 2000.ms,
                  curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: 140,
              left: 18,
              child: Transform.rotate(
                angle: -0.25,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🔒', style: TextStyle(fontSize: 24)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 600.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),
            Positioned(
              top: 220,
              left: 14,
              child: Transform.rotate(
                angle: 0.35,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 28)),
                ),
              )
                  .animate(
                      onPlay: (c) => c.repeat(reverse: true), delay: 1200.ms)
                  .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2000.ms,
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Privacy first.\nAlways.',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      color: AppTheme.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.selectedGreenTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppTheme.selectedGreen.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded,
                            size: 16, color: AppTheme.successMint),
                        const SizedBox(width: 6),
                        Text(
                          'Everything stays on your phone',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successMint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...[
                    const _PermissionTile(
                      icon: Icons.keyboard_outlined,
                      title: 'Typing patterns',
                      description: 'Analyses rhythm and speed — never content.',
                      accentColor: AppTheme.selectedGreen,
                    ),
                    const _PermissionTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Phone usage',
                      description: 'Session length and app-switching patterns.',
                      accentColor: AppTheme.warmAccent,
                    ),
                    const _PermissionTile(
                      icon: Icons.face_outlined,
                      title: 'Facial scan (optional)',
                      description: 'One-time valence reading. On-device only.',
                      accentColor: Color(0xFF6EAAFF),
                    ),
                  ].asMap().entries.map((e) => Padding(
                        padding: EdgeInsets.only(bottom: e.key < 2 ? 10 : 0),
                        child: e.value
                            .animate(delay: (e.key * 80).ms)
                            .fadeIn(duration: 400.ms)
                            .slideX(
                                begin: -0.12,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic),
                      )),
                  const Spacer(),
                  _PillButton(label: "Got it — let's go >", onPressed: onNext),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title, description;
  final Color accentColor;
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              Text(description,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Meet Mochi Page ──────────────────────────────────────────────────────────

class MeetMochiPage extends StatefulWidget {
  final String name;
  final VoidCallback onFinish;
  const MeetMochiPage({required this.name, required this.onFinish, super.key});

  @override
  State<MeetMochiPage> createState() => _MeetMochiPageState();
}

class _MeetMochiPageState extends State<MeetMochiPage>
    with TickerProviderStateMixin {
  late final VideoPlayerController _videoCtrl;
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  bool _showContent = false;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(vsync: this, duration: 800.ms);
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _videoCtrl = VideoPlayerController.asset('assets/videos/meet_mochi.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoInitialized = true);
        _videoCtrl.setLooping(true);
        _videoCtrl.play();

        // Show text after a short delay once video starts
        Future.delayed(1200.ms, () {
          if (mounted) {
            setState(() => _showContent = true);
            _textCtrl.forward();
          }
        });
      });
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.name.trim().isNotEmpty ? widget.name.trim() : 'you';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Background
        if (_videoInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoCtrl.value.size.width,
              height: _videoCtrl.value.size.height,
              child: VideoPlayer(_videoCtrl),
            ),
          )
        else
          Container(color: AppTheme.backgroundDeep), // Fallback while loading

        // Subtle gradient overlay to ensure text is readable against the video
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Text & Button Overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                if (_showContent) ...[
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            'Meet Mochi! 🌿',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 38,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Hey $displayName! I'm Mochi 🐻\nI'll keep an eye on how you're doing and check in when it matters. Let's grow together 🌱",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(height: 120),
                const Spacer(flex: 2),
                if (_showContent)
                  FadeTransition(
                    opacity: _textFade,
                    child: _PillButton(
                      label: "Let's thrive 🌿",
                      onPressed: widget.onFinish,
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarOption {
  final String id, emoji, name, unlock, tagline, description;
  final bool locked;
  final Color color;
  const _AvatarOption({
    required this.id,
    required this.emoji,
    required this.name,
    required this.locked,
    required this.unlock,
    required this.tagline,
    required this.description,
    required this.color,
  });
}

// ─── Tap-scale wrapper ────────────────────────────────────────────────────────

class _TapScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScaleWrapper({required this.child, required this.onTap});

  @override
  State<_TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<_TapScaleWrapper> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _tapCount++);
        widget.onTap();
      },
      child: widget.child
          .animate(key: ValueKey(_tapCount), autoPlay: _tapCount > 0)
          .scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1.0, 1.0),
            duration: 150.ms,
          ),
    );
  }
}
