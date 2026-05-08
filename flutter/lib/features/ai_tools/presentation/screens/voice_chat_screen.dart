import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/strings_bn.dart';

class VoiceChatScreen extends StatelessWidget {
  const VoiceChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003300),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          StringsBn.voiceChat,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003300), Color(0xFFF8FBF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.15],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildChatBubble(
                    context,
                    'নমস্কার! আমি FarmAI। আপনার গবাদি পশুর কোনো সমস্যা কি আজ আমাকে জানাতে চান?',
                    false,
                  ),
                  _buildChatBubble(
                    context,
                    'আমার ধানের পাতায় লালচে দাগ দেখা যাচ্ছে। এটা কি কোনো রোগ?',
                    true,
                  ),
                  _buildChatBubble(
                    context,
                    'এটি ধানের ব্লাস্ট রোগ হতে পারে। আবহাওয়ায় আর্দ্রতা বেশি থাকলে এটি ছড়ায়। প্রতিকার হিসেবে আপনি ট্রাইসাইক্লাজোল জাতীয় ওষুধ ব্যবহার করতে পারেন।',
                    false,
                    title: "সম্ভাব্য রোগ: 'ব্লাস্ট রোগ'",
                  ),
                ],
              ),
            ),
            _buildModernVoiceControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, String text, bool isUser, {String? title}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 8),
            bottomRight: Radius.circular(isUser ? 8 : 24),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003300).withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: isUser ? null : Border.all(color: const Color(0xFFF0F4F7), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUser ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF004D40),
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF2C3E50),
                fontSize: 15,
                height: 1.5,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildModernVoiceControl() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFECF0F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'আমি শুনছি...',
            style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 24),
          _buildWaveIndicator(),
          const SizedBox(height: 40),
          _buildMicButton(),
        ],
      ),
    );
  }

  Widget _buildWaveIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(9, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 4,
          height: 15 + (index % 5 * 15).toDouble(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00897B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ).animate(onPlay: (controller) => controller.repeat())
          .scaleY(duration: (400 + index * 80).ms, curve: Curves.easeInOut, begin: 0.3, end: 1.0);
      }),
    );
  }

  Widget _buildMicButton() {
    return Container(
      height: 85,
      width: 85,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF003300), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003300).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(Icons.mic_rounded, color: Colors.white, size: 40),
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(duration: 1200.ms, begin: const Offset(1, 1), end: const Offset(1.08, 1.08), curve: Curves.easeInOut);
  }
}
