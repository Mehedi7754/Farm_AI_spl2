import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;

  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  bool _isVoiceMode = true;
  bool _isQueryProcessing = false;

  String _currentSpeechWords = '';
  String _statusText = 'কথা বলতে মাইকে চাপুন';

  List<Map<String, String>> _messages = [];

  static const String _prefsKey = 'farm_voice_chat_history_v14';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _loadSavedChatHistory();
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
      _speech.cancel();
    } catch (_) {}
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _extractCleanJsonAnswer(String rawText) {
    if (rawText.trim().isEmpty) return '';

    String answerText = rawText;

    try {
      final parsed = jsonDecode(rawText);
      if (parsed is Map && parsed.containsKey('answer')) {
        answerText = parsed['answer'].toString();
      }
    } catch (_) {
      final regExp = RegExp(r'"answer"\s*:\s*"([^"]+)"');
      final match = regExp.firstMatch(rawText);
      if (match != null && match.group(1) != null) {
        answerText = match.group(1)!.replaceAll(r'\"', '"').replaceAll(r'\n', ' ');
      }
    }

    // Strip out any XML-like tags (e.g. <thought>, <tool_call>)
    answerText = answerText.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');

    final noEmojis = answerText.replaceAll(RegExp(
      r'[\u{1F600}-\u{1F64F}'
      r'|\u{1F300}-\u{1F5FF}'
      r'|\u{1F680}-\u{1F6FF}'
      r'|\u{1F1E6}-\u{1F1FF}'
      r'|\u{2600}-\u{26FF}'
      r'|\u{2700}-\u{27BF}'
      r'|\u{1F900}-\u{1F9FF}'
      r'|\u{1FA70}-\u{1FAFA}'
      r'|\u{200D}'
      r'|\u{FE0F}]',
      unicode: true,
    ), '');

    return noEmojis
        .replaceAll(RegExp(r'[\{\}\"\[\]]'), '')
        .replaceAll(RegExp(r'[\*\#\-\_\`\~\:\;]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _loadSavedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        if (mounted) {
          setState(() {
            _messages = list.map((item) => Map<String, String>.from(item)).toList();
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToSave = _messages.map((item) => Map<String, String>.from(item)).toList();
      final jsonString = jsonEncode(listToSave);
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _startNewChat() async {
    try {
      await _flutterTts.stop();
      await _speech.stop();
    } catch (_) {}
    setState(() {
      _messages.clear();
      _isListening = false;
      _isSpeaking = false;
      _isLoading = false;
      _statusText = 'নতুন চ্যাট শুরু হয়েছে। কথা বলতে মাইকে চাপুন।';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void _initTts() async {
    _flutterTts = FlutterTts();

    try {
      await _flutterTts.awaitSpeakCompletion(true);
      final engines = await _flutterTts.getEngines;
      if (engines is List && engines.contains("com.google.android.tts")) {
        await _flutterTts.setEngine("com.google.android.tts");
      }
    } catch (e) {
      debugPrint('TTS Engine set error: $e');
    }

    try {
      await _flutterTts.setLanguage("bn-BD");
    } catch (_) {
      try {
        await _flutterTts.setLanguage("bn-IN");
      } catch (_) {
        try {
          await _flutterTts.setLanguage("bn");
        } catch (_) {}
      }
    }

    await _flutterTts.setSpeechRate(0.58);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _statusText = 'কথা বলতে মাইকে চাপুন';
        });
        if (_isVoiceMode) {
          _startListening();
        }
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<bool> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          // Only update UI state here — do NOT call _sendQueryToGroq.
          // _sendQueryToGroq is ONLY triggered from onResult(finalResult: true)
          // to prevent duplicate messages.
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('STT Error: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusText = 'মাইক্রোফোন সংযোগে সমস্যা। আবার চাপুন।';
            });
          }
        },
      );
      if (mounted) setState(() {});
      return _isSpeechAvailable;
    } catch (e) {
      debugPrint('Speech init error: $e');
      return false;
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      // User manually stopped — capture text BEFORE stopping speech
      // so onStatus('done') fires with nothing left to send.
      final capturedText = _currentSpeechWords.trim();
      _currentSpeechWords = '';
      try {
        await _speech.stop();
      } catch (_) {}
      setState(() {
        _isListening = false;
        _statusText = 'কথা বলতে মাইকে চাপুন';
      });
      // Send only if onResult(finalResult) has NOT already sent this text
      if (capturedText.isNotEmpty && !_isQueryProcessing) {
        _sendQueryToGroq(capturedText);
      }
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    if (_isSpeaking) {
      try {
        await _flutterTts.stop();
      } catch (_) {}
      setState(() => _isSpeaking = false);
    }

    if (!_isSpeechAvailable) {
      final ok = await _initSpeech();
      if (!ok) {
        setState(() {
          _isListening = false;
          _statusText = 'মাইক্রোফোন চালু করা যায়নি। পারমিশন চেক করুন।';
        });
        return;
      }
    }

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    setState(() {
      _isListening = true;
      _statusText = 'কথা বলুন, শুনছি...';
      _currentSpeechWords = '';
    });

    try {
      await _speech.listen(
        localeId: 'bn_BD',
        onResult: (result) {
          if (mounted) {
            setState(() {
              _currentSpeechWords = result.recognizedWords;
              if (result.recognizedWords.isNotEmpty) {
                _statusText = 'শুনছি: ${result.recognizedWords}';
              }
            });
            if (result.finalResult) {
              final text = result.recognizedWords.trim();
              if (text.isNotEmpty) {
                // Clear BEFORE stopping so onStatus callback sees empty words
                _currentSpeechWords = '';
                try {
                  _speech.stop();
                } catch (_) {}
                setState(() {
                  _isListening = false;
                });
                _sendQueryToGroq(text);
              }
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Listen exception: $e');
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _sendQueryToGroq(String userPrompt) async {
    if (userPrompt.trim().isEmpty) return;
    if (_isQueryProcessing) return;

    _isQueryProcessing = true;

    if (_isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    final cleanPrompt = userPrompt.trim();

    setState(() {
      _messages.add({'text': cleanPrompt, 'isUser': 'true'});
      _isLoading = true;
      _isListening = false;
      _statusText = 'ভেটেরিনারি উত্তর তৈরি হচ্ছে...';
    });

    _textController.clear();
    _scrollToBottom();
    await _saveChatHistory();

    try {
      final data = await ApiClient.voiceChat(cleanPrompt, language: 'bn');
      if (mounted) {
        final replyText = data['reply']?.toString() ?? '';
        if (replyText.isNotEmpty) {
          final cleanReply = _extractCleanJsonAnswer(replyText);
          setState(() {
            _isLoading = false;
            _messages.add({'text': cleanReply.isNotEmpty ? cleanReply : replyText, 'isUser': 'false'});
            _statusText = 'উত্তর প্রদান করা হচ্ছে...';
          });
          _scrollToBottom();
          await _saveChatHistory();
          _speakReply(cleanReply.isNotEmpty ? cleanReply : replyText);
          return;
        }

        setState(() {
          _isLoading = false;
          _statusText = 'সার্ভার সংযোগ সমস্যা। আবার চেষ্টা করুন।';
        });
      }
    } catch (e) {
      debugPrint('Voice Chat API Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = 'ইন্টারনেট বা সার্ভার সমস্যা।';
        });
      }
    } finally {
      _isQueryProcessing = false;
    }
  }

  void _speakReply(String text) async {
    final cleanTtsText = _extractCleanJsonAnswer(text);
    if (cleanTtsText.isEmpty) return;

    try {
      await _flutterTts.stop();
      setState(() => _isSpeaking = true);
      final res = await _flutterTts.speak(cleanTtsText);
      debugPrint('TTS speak result code: $res');
    } catch (e) {
      debugPrint('TTS speak exception: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'FarmAI ভেটেরিনারি সহকারী',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add_comment_rounded, size: 16, color: Colors.white),
            label: const Text(
              'নতুন চ্যাট',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Voice vs Text Chat Mode Switcher Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeToggleButton(
                  title: 'ভয়েস মোড',
                  icon: Icons.graphic_eq_rounded,
                  isSelected: _isVoiceMode,
                  onTap: () {
                    setState(() => _isVoiceMode = true);
                  },
                ),
                const SizedBox(width: 12),
                _buildModeToggleButton(
                  title: 'টেক্সট মোড',
                  icon: Icons.chat_bubble_outline_rounded,
                  isSelected: !_isVoiceMode,
                  onTap: () {
                    try {
                      if (_isListening) _speech.stop();
                    } catch (_) {}
                    setState(() {
                      _isVoiceMode = false;
                      _isListening = false;
                    });
                  },
                ),
              ],
            ),
          ),

          // Message Bubbles List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pets_rounded, color: Color(0xFF059669), size: 32),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'গবাদিপশু সংক্রান্ত যেকোনো প্রশ্ন করুন',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isVoiceMode ? 'মাইকে চেপে বাংলায় কথা বলুন' : 'নিচের বক্সে আপনার প্রশ্নটি লিখুন',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(context, msg['text']!, msg['isUser'] == 'true', index);
                    },
                  ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF059669)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'ভেটেরিনারি উত্তর তৈরি হচ্ছে...',
                    style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Bottom Control Area
          _isVoiceMode ? _buildVoiceHeroArea() : _buildTextInputArea(),
        ],
      ),
    );
  }

  Widget _buildModeToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, String text, bool isUser, int index) {
    return Align(
      key: ValueKey('voice_msg_${index}_${text.hashCode}'),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_rounded : Icons.psychology_rounded,
                  size: 14,
                  color: isUser ? Colors.white70 : const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'আপনার প্রশ্ন' : 'FarmAI ভেটেরিনারি পরামর্শ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white70 : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : const Color(0xFF0F172A),
                height: 1.45,
                fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildVoiceHeroArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF059669),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Central Hero Mic Button
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF059669),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? const Color(0xFFEF4444) : const Color(0xFF059669)).withOpacity(0.35),
                    blurRadius: _isListening ? 20 : 10,
                    spreadRadius: _isListening ? 5 : 1,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ).animate(target: _isListening ? 1 : 0).scale(
                duration: 500.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
              ),

          const SizedBox(height: 10),
          Text(
            _isListening ? 'থামাতে মাইকে চাপুন' : 'কথা বলা শুরু করতে মাইকে চাপুন',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'আপনার পশুর সমস্যাটি লিখুন...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (text) => _sendQueryToGroq(text),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF059669), size: 24),
              onPressed: () => _sendQueryToGroq(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
