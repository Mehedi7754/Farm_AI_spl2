import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../../core/services/notification_store.dart';
import '../../../utilities/presentation/providers/weather_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../animals/presentation/providers/livestock_provider.dart';
import '../../../utilities/presentation/providers/financial_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.94);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentCarouselIndex + 1) % 5;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final authState = ref.watch(authProvider);
    final livestockState = ref.watch(livestockProvider);

    final farmName = authState.user?['name'] != null ? '${authState.user!['name']}-এর খামার' : 'আমার খামার';
    final weatherData = weatherState.data;
    final temp = (weatherData?['currentTemperature'] as num?)?.toDouble() ?? 31.0;
    
    final animalCount = livestockState.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,
        titleSpacing: 18,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      'FarmAI',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        'স্মার্ট খামার',
                        style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  farmName,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: NotificationStore().unreadCountNotifier,
                builder: (context, unreadCount, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        unreadCount > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: const Color(0xFF047857),
                        size: 20,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/chat-list'),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF047857), size: 20),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3), width: 1),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Compact & Beautiful Voice Assistance Banner Card with visible background photo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCompactVoiceHeroCard(context),
            ),
            const SizedBox(height: 16),

            // 2. Clean Section Header: Quick Metrics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.insights_rounded, color: Color(0xFF047857), size: 19),
                  SizedBox(width: 8),
                  Text(
                    'খামারের সার্বিক অবস্থা',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms),
            ),

            const SizedBox(height: 10),

            // 3. Compact Auto-Scrolling Photo Carousel (High Photo Visibility)
            _buildCompactPhotoCarousel(context, weatherData, '${temp.round()}°C', '$animalCount টি'),
            const SizedBox(height: 22),

            // 4. Services Grid Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.grid_view_rounded, color: Color(0xFF047857), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'খামার সেবাসমূহ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      '৮ টি সেবামূলক মডিউল',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
            ),

            const SizedBox(height: 14),

            // 5. Unique Signature Style Feature Cards Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildUniqueSignatureServiceGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactVoiceHeroCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai/voice'),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Visible Background Landscape Photo
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_landscape.png',
                fit: BoxFit.cover,
              ),
            ),
            // Semi-Transparent Gradient for Contrast
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xF2047857), Color(0xD9065F46)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Foreground Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, color: Color(0xFF047857), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'কথা বলে সেবা নিন',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.graphic_eq_rounded, color: Color(0xFF6EE7B7), size: 16),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'পশুর লক্ষণ বা সমস্যা মুখে বলুন',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'কথা বলুন',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 9),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildCompactPhotoCarousel(BuildContext context, Map<String, dynamic>? weatherData, String temp, String animalCount) {
    final humidity = (weatherData?['humidity'] as num?)?.toInt() ?? 65;
    final wind = (weatherData?['windSpeed'] as num?)?.toDouble() ?? 14.0;
    final precip = (weatherData?['forecast'] as List?)?.isNotEmpty == true
        ? ((weatherData!['forecast'][0]['precipitation'] as num?)?.toDouble() ?? 2.5)
        : 2.5;

    final rawLocName = ref.watch(weatherProvider).locationName;
    final locName = rawLocName.isNotEmpty ? rawLocName : 'ঢাকা, বাংলাদেশ';

    // 1. Calculate Real Cattle stats
    final livestockState = ref.watch(livestockProvider);
    final animalsList = livestockState.value ?? [];
    int healthyCount = 0;
    int boundCollars = 0;
    for (var cow in animalsList) {
      final health = (cow['health'] ?? 'সুস্থ').toString().toLowerCase();
      if (health.contains('সুস্থ') || health.contains('চমৎকার') || health.contains('healthy') || health.contains('excellent')) {
        healthyCount++;
      }
      final isBound = cow['isBound'] == true;
      final collarId = cow['collarId']?.toString();
      if (isBound || (collarId != null && collarId.isNotEmpty && collarId != 'N/A')) {
        boundCollars++;
      }
    }
    final int animalCountNum = animalsList.length;
    final double healthPercentage = animalCountNum > 0 ? (healthyCount / animalCountNum) * 100 : 100.0;

    // 2. Calculate Real Financial metrics
    final financialState = ref.watch(financialProvider);
    final transactions = financialState.value ?? [];

    double totalMilkLiters = 0;
    int currentMonthIncome = 0;
    int currentMonthExpense = 0;
    final now = DateTime.now();

    for (var t in transactions) {
      // Liters extraction
      if (t['isIncome'] == true && t['category'] == 'দুধ বিক্রি') {
        final title = t['title'].toString();
        final regExp = RegExp(r'(\d+)\s*(?:লিটার|লিলি|l|L|liter|litre)');
        final match = regExp.firstMatch(title);
        if (match != null) {
          totalMilkLiters += double.tryParse(match.group(1)!) ?? 0;
        } else {
          final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
          totalMilkLiters += (amount / 75.0); // Estimate: 75 Taka per liter
        }
      }

      // Profit calculations for current month
      final tsRaw = t['timestamp'];
      final ts = tsRaw is DateTime ? tsRaw : (tsRaw != null ? DateTime.tryParse(tsRaw.toString()) : null);
      if (ts != null && ts.year == now.year && ts.month == now.month) {
        final amount = (t['amount'] as num).toInt();
        if (t['isIncome'] == true) {
          currentMonthIncome += amount;
        } else {
          currentMonthExpense += amount;
        }
      }
    }
    final monthlyProfit = currentMonthIncome - currentMonthExpense;

    final cards = [
      {
        'title': 'আজকের আবহাওয়া পূর্বাভাস',
        'val': temp,
        'sub': '$locName • আর্দ্রতা: $humidity% | বাতাস: ${wind.round()}km/h',
        'icon': Icons.wb_sunny_rounded,
        'gradient': [const Color(0xFF047857), const Color(0xFF0F766E)],
        'accentIcon': Icons.cloud_queue_rounded,
        'btnText': 'বিস্তারিত',
        'route': '/weather',
        'extraMetrics': [
          {'icon': Icons.water_drop_rounded, 'label': '$humidity%'},
          {'icon': Icons.air_rounded, 'label': '${wind.round()}km/h'},
          {'icon': Icons.umbrella_rounded, 'label': '${precip.toStringAsFixed(1)}mm'},
        ],
      },
      {
        'title': 'গবাদিপশু খামার ট্র্যাকিং',
        'val': '$animalCountNum টি পশু নিবন্ধিত',
        'sub': 'শতকরা ${healthPercentage.toStringAsFixed(0)}% পশুর স্বাস্থ্য চমৎকার ও সুস্থ',
        'icon': Icons.pets_rounded,
        'accentIcon': Icons.agriculture_rounded,
        'gradient': [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        'btnText': 'তালিকা',
        'route': '/animals',
      },

      {
        'title': 'চলতি মাসের খামার লাভ',
        'val': '৳$monthlyProfit নিট লাভ',
        'sub': 'আয়: ৳$currentMonthIncome | ব্যয়: ৳$currentMonthExpense',
        'icon': Icons.trending_up_rounded,
        'accentIcon': Icons.monetization_on_rounded,
        'gradient': [const Color(0xFF6D28D9), const Color(0xFF5B21B6)],
        'btnText': 'বিবরণী',
        'route': '/accounting',
      },
      {
        'title': 'স্মার্ট কলার সেন্সর',
        'val': boundCollars > 0 ? '$boundCollars টি কলার সক্রিয়' : 'কোনো কলার সক্রিয় নেই',
        'sub': boundCollars > 0 ? 'রিয়েল-টাইম জিপিএস ও মোশন ট্র্যাকিং সক্রিয়' : 'কলার আইডি সংযুক্ত করতে ট্র্যাকিং যান',
        'icon': Icons.sensors_rounded,
        'accentIcon': Icons.cell_tower_rounded,
        'gradient': [const Color(0xFFBE185D), const Color(0xFF9D174D)],
        'btnText': 'ট্র্যাকিং',
        'route': '/collar',
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 112, // Compact, sleek height
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final item = cards[index];
              final gradientColors = item['gradient'] as List<Color>;

              return GestureDetector(
                onTap: () => context.push(item['route'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Highly Visible Background Photo
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/login_landscape.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Lightened Gradient Overlay for High Photo Visibility
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                gradientColors[0].withOpacity(0.78),
                                gradientColors[1].withOpacity(0.70),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      // Graphic Accent Icon
                      Positioned(
                        right: -10,
                        bottom: -15,
                        child: Icon(
                          item['accentIcon'] as IconData,
                          size: 95,
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),

                      // Foreground Content
                      Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(item['icon'] as IconData, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item['title'] as String,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.98),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    item['val'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item['sub'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.28),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.45)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['btnText'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Carousel Page Indicators (Dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            final isSel = index == _currentCarouselIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: isSel ? 18 : 5,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUniqueSignatureServiceGrid(BuildContext context) {
    final list = [
      {
        'title': StringsBn.aiSymptom,
        'sub': 'লক্ষণ ও ছবি দিয়ে রোগ পরীক্ষা',
        'tag': 'এআই ভিশন',
        'icon': Icons.psychology_rounded,
        'accent': const Color(0xFF0F766E),
        'bgTint': const Color(0xFFF0FDF4),
        'border': const Color(0xFF99F6E4),
        'route': '/ai/symptom',
      },
      {
        'title': StringsBn.cattleManagement,
        'sub': 'পশুর তালিকা ও স্বাস্থ্য ট্র্যাকিং',
        'tag': 'খামার ট্র্যাকিং',
        'icon': Icons.pets_rounded,
        'accent': const Color(0xFF334155),
        'bgTint': const Color(0xFFF8FAFC),
        'border': const Color(0xFFCBD5E1),
        'route': '/animals',
      },
      {
        'title': StringsBn.hospitalFinder,
        'sub': 'নিকটস্থ হাসপাতাল ও জিপিএস',
        'tag': 'ইমার্জেন্সি',
        'icon': Icons.local_hospital_rounded,
        'accent': const Color(0xFFBE123C),
        'bgTint': const Color(0xFFFFF1F2),
        'border': const Color(0xFFFECDD3),
        'route': '/hospital',
      },
      {
        'title': StringsBn.vaccineReminder,
        'sub': 'টিকা ও কৃমিনাশক অ্যালার্ট',
        'tag': 'বিজ্ঞপ্তি',
        'icon': Icons.vaccines_rounded,
        'accent': const Color(0xFF6D28D9),
        'bgTint': const Color(0xFFF5F3FF),
        'border': const Color(0xFFDDD6FE),
        'route': '/reminders',
      },
      {
        'title': StringsBn.accounting,
        'sub': 'দুধ বিক্রি ও লাভ-ক্ষতি হিসাব',
        'tag': 'স্মার্ট লেজার',
        'icon': Icons.payments_rounded,
        'accent': const Color(0xFFB45309),
        'bgTint': const Color(0xFFFFFBEB),
        'border': const Color(0xFFFDE68A),
        'route': '/accounting',
      },
      {
        'title': StringsBn.weather,
        'sub': 'বৃষ্টি ও তাপমাত্রা পূর্বাভাস',
        'tag': 'পূর্বাভাস',
        'icon': Icons.cloud_sync_rounded,
        'accent': const Color(0xFF0369A1),
        'bgTint': const Color(0xFFF0F9FF),
        'border': const Color(0xFFBAE6FD),
        'route': '/weather',
      },
      {
        'title': StringsBn.teleVet,
        'sub': 'ডাক্তারের সাথে সরাসরি কল',
        'tag': '২৪/৭ কল',
        'icon': Icons.video_call_rounded,
        'accent': const Color(0xFFBE185D),
        'bgTint': const Color(0xFFFDF2F8),
        'border': const Color(0xFFFBCFE8),
        'route': '/find-vet',
      },
      {
        'title': StringsBn.medicine,
        'sub': 'ওষুধের নির্দেশিকা ও মাত্রা',
        'tag': 'গাইড',
        'icon': Icons.medication_rounded,
        'accent': const Color(0xFFC2410C),
        'bgTint': const Color(0xFFFFF7ED),
        'border': const Color(0xFFFFEDD5),
        'route': '/medicine',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.94,
      ),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final accent = item['accent'] as Color;
        final bgTint = item['bgTint'] as Color;
        final border = item['border'] as Color;

        return GestureDetector(
          onTap: () => context.push(item['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  bgTint.withValues(alpha: 0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon Ring + Feature Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            bgTint,
                            border.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(item['icon'] as IconData, color: accent, size: 22),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgTint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border.withValues(alpha: 0.9)),
                      ),
                      child: Text(
                        item['tag'] as String,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Middle Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['sub'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Bottom Action Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: bgTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: border),
                      ),
                      child: Center(
                        child: Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 350.ms, delay: (idx * 35).ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic);
      },
    );
  }
}
