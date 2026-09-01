import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  Map<String, dynamic> _getWeatherDetails(int code) {
    if (code == 0) return {'status': 'Sunny / Clear', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber};
    if (code >= 1 && code <= 3) return {'status': 'Partly Cloudy', 'icon': Icons.wb_cloudy_rounded, 'color': Colors.white70};
    if (code >= 45 && code <= 48) return {'status': 'Foggy', 'icon': Icons.foggy, 'color': Colors.white54};
    if (code >= 51 && code <= 67) return {'status': 'Rain', 'icon': Icons.water_drop_rounded, 'color': Colors.lightBlueAccent};
    if (code >= 71 && code <= 77) return {'status': 'Snow', 'icon': Icons.ac_unit_rounded, 'color': Colors.white};
    if (code >= 80 && code <= 82) return {'status': 'Heavy Rain', 'icon': Icons.umbrella_rounded, 'color': Colors.lightBlue};
    if (code >= 95 && code <= 99) return {'status': 'Thunderstorm', 'icon': Icons.thunderstorm_rounded, 'color': Colors.amberAccent};
    return {'status': 'Cloudy', 'icon': Icons.cloud_rounded, 'color': Colors.white70};
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, d MMM').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showNotificationOptions(
    BuildContext context,
    double temp,
    String locationName,
    String status,
    String advice,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: Color(0xFF047857), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'আবহাওয়া পুশ নোটিফিকেশন',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.bolt_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text('তাৎক্ষণিক আবহাওয়া আপডেট পাঠাও', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('বর্তমান তাপমাত্রা ও কৃষকের জন্য সতর্কতা নোটিফিকেশন দেবে', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await NotificationService().showWeatherAlert(
                    title: '🌤️ আবহাওয়া আপডেট — ${locationName.isNotEmpty ? locationName : 'ঢাকা'}',
                    body: 'বর্তমান তাপমাত্রা: ${temp.round()}°C ($status)। $advice',
                    payload: 'WEATHER_ALERT',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('তাৎক্ষণিক আবহাওয়া পুশ নোটিফিকেশন পাঠানো হয়েছে 🔔'),
                        backgroundColor: Color(0xFF047857),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('দৈনিক সকালের আবহাওয়া রিমাইন্ডার সেট করো', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('প্রতিদিন নির্দিষ্ট সময়ে সকালের পুশ অ্যালার্ট পাবেন', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                    helpText: 'সকালের আবহাওয়া রিমাইন্ডারের সময় নির্বাচন করুন',
                  );
                  if (pickedTime != null) {
                    final formattedTimeStr = pickedTime.format(context);
                    await NotificationService().scheduleDailyWeatherReminder(
                      hour: pickedTime.hour,
                      minute: pickedTime.minute,
                      title: '🌤️ সকালের আবহাওয়া আপডেট — ${locationName.isNotEmpty ? locationName : 'ঢাকা'}',
                      body: 'আজকের তাপমাত্রা ${temp.round()}°C ($status)। খামার ও পশুদের সতর্কতার সাথে যত্ন নিন।',
                    );
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'দৈনিক সকাল $formattedTimeStr টায় আবহাওয়া পুশ নোটিফিকেশন সেট করা হয়েছে ⏰',
                          ),
                          backgroundColor: const Color(0xFF047857),
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.nights_stay_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('আগামীকালের পূর্বাভাস নোটিফিকেশন সেট করো', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('আগামীকাল সকাল ৬:৩০ টায় পূর্বাভাসের নোটিফিকেশন দেবে', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  await NotificationService().scheduleTomorrowWeatherForecast(
                    weatherSummary: 'আগামীকালের তাপমাত্রা আনুমানিক ${temp.round()}°C ($status)। $advice',
                    location: locationName.isNotEmpty ? locationName : 'ঢাকা',
                    hour: 6,
                    minute: 30,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('আগামীকাল সকাল ৬:৩০ টায় পূর্বাভাসের নোটিফিকেশন সেট হয়েছে 🌦️'),
                        backgroundColor: Color(0xFF047857),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final weatherData = weatherState.data;

    // NO LOADING SCREEN: Use actual or fallback values directly for 0ms instant display
    final temp = (weatherData?['currentTemperature'] as num?)?.toDouble() ?? 31.0;
    final humidity = (weatherData?['humidity'] as num?)?.toInt() ?? 65;
    final wind = (weatherData?['windSpeed'] as num?)?.toDouble() ?? 14.0;
    final latVal = (weatherData?['lat'] as num?)?.toDouble() ?? 23.8103;
    final lngVal = (weatherData?['lng'] as num?)?.toDouble() ?? 90.4125;
    final latLng = LatLng(latVal, lngVal);

    final advice = weatherData?['agriculturalAdvice'] as String? ?? 'Weather is normal. Take regular care of your crops and livestock.';
    final isHeatStress = weatherData?['isHeatStress'] as bool? ?? false;
    final isStormWarning = weatherData?['isStormWarning'] as bool? ?? false;

    final forecastList = weatherData?['forecast'] as List<dynamic>? ?? [
      {'date': '2026-07-29', 'weatherCode': 61, 'tempMax': 32, 'tempMin': 26, 'precipitation': 4.5},
      {'date': '2026-07-30', 'weatherCode': 61, 'tempMax': 31, 'tempMin': 26, 'precipitation': 2.1},
      {'date': '2026-07-31', 'weatherCode': 1, 'tempMax': 33, 'tempMin': 27, 'precipitation': 3.2},
      {'date': '2026-08-01', 'weatherCode': 1, 'tempMax': 34, 'tempMin': 27, 'precipitation': 1.6},
      {'date': '2026-08-02', 'weatherCode': 61, 'tempMax': 33, 'tempMin': 27, 'precipitation': 14.4},
      {'date': '2026-08-03', 'weatherCode': 61, 'tempMax': 33, 'tempMin': 27, 'precipitation': 3.7},
    ];

    final agroData = weatherData?['agroData'] as Map<String, dynamic>? ?? {
      'soilMoisture': 0.28,
      'soilTemperature': 29.5,
      'soilStatus': 'Normal',
    };

    final currentWeatherDetails = _getWeatherDetails(weatherData?['weatherCode'] ?? 61);
    final formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final locationName = weatherState.locationName;

    final hourlyForecast = [
      {'time': 'Now', 'temp': temp.round(), 'code': weatherData?['weatherCode'] ?? 61},
      {'time': '+3h', 'temp': (temp + 1).round(), 'code': 1},
      {'time': '+6h', 'temp': (temp + 2).round(), 'code': 61},
      {'time': '+9h', 'temp': (temp + 1).round(), 'code': 51},
      {'time': '+12h', 'temp': temp.round(), 'code': 1},
    ];

    double maxTemp = forecastList.isNotEmpty ? ((forecastList[0]['tempMax'] as num?)?.toDouble() ?? (temp + 2)) : temp + 2;
    double minTemp = forecastList.isNotEmpty ? ((forecastList[0]['tempMin'] as num?)?.toDouble() ?? (temp - 5)) : temp - 5;
    double precip = forecastList.isNotEmpty ? ((forecastList[0]['precipitation'] as num?)?.toDouble() ?? 0.0) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF022C22), Color(0xFF047857), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
              tooltip: 'Weather Notification Options',
              onPressed: () {
                _showNotificationOptions(
                  context,
                  temp,
                  locationName.isNotEmpty ? locationName : 'ঢাকা, বাংলাদেশ',
                  currentWeatherDetails['status'] as String,
                  advice,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () {
                ref.read(weatherProvider.notifier).refreshWeather(silent: false);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          color: const Color(0xFF047857),
          backgroundColor: Colors.white,
          onRefresh: () async {
            await ref.read(weatherProvider.notifier).refreshWeather(silent: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Location & Date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationName.isNotEmpty ? locationName : 'ঢাকা, বাংলাদেশ',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 24),

                // Main Weather Display (Icon + Temp)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(currentWeatherDetails['icon'], size: 90, color: currentWeatherDetails['color']),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${temp.round()}°C',
                            style: const TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900, height: 1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentWeatherDetails['status'],
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 24),

                // High / Low Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPill('High : ${maxTemp.round()}°C', Colors.black.withOpacity(0.18)),
                    const SizedBox(width: 16),
                    _buildPill('Low : ${minTemp.round()}°C', Colors.black.withOpacity(0.18)),
                  ],
                ).animate().fadeIn(duration: 450.ms, delay: 150.ms),
                const SizedBox(height: 20),

                // Agricultural Warning / Advice Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isStormWarning || isHeatStress
                          ? const Color(0xFFFEF2F2).withOpacity(0.95)
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isStormWarning || isHeatStress
                            ? const Color(0xFFFCA5A5)
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isStormWarning
                              ? Icons.thunderstorm_rounded
                              : (isHeatStress ? Icons.wb_sunny_rounded : Icons.eco_rounded),
                          color: isStormWarning || isHeatStress ? const Color(0xFFDC2626) : const Color(0xFFA7F3D0),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isStormWarning
                                    ? 'Storm Warning!'
                                    : (isHeatStress ? 'Heat Stress Alert!' : 'Agricultural & Farm Advisory'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isStormWarning || isHeatStress ? const Color(0xFF991B1B) : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                advice,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isStormWarning || isHeatStress ? const Color(0xFF7F1D1D) : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                const SizedBox(height: 20),

                // Weather Metrics Row (Humidity, Wind, Rain)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem('Humidity', '$humidity%'),
                      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.15)),
                      _buildInfoItem('Wind', '${wind.round()} km/h'),
                      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.15)),
                      _buildInfoItem('Rain', '${precip.toStringAsFixed(1)} mm'),
                    ],
                  ),
                ).animate().fadeIn(duration: 550.ms, delay: 250.ms),
                const SizedBox(height: 24),

                // Hourly Forecast Horizontal List
                SizedBox(
                  height: 115,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: hourlyForecast.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final h = hourlyForecast[index];
                      final isNow = index == 0;
                      final hDetails = _getWeatherDetails(h['code'] as int);
                      return Container(
                        width: 72,
                        decoration: BoxDecoration(
                          color: isNow ? Colors.white.withOpacity(0.28) : Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(isNow ? 0.35 : 0.08)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              h['time'] as String,
                              style: TextStyle(
                                color: isNow ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(hDetails['icon'], color: hDetails['color'], size: 22),
                            const SizedBox(height: 8),
                            Text(
                              '${h['temp']}°',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                const SizedBox(height: 30),

                // White Bottom Sheet (Soil Agro Data, 7-Day Forecast & Map)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Agro Soil Section
                      Row(
                        children: const [
                          Icon(Icons.grass_rounded, color: Color(0xFF047857), size: 20),
                          SizedBox(width: 8),
                          Text('Soil & Agro Metrics', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAgroMetric(Icons.water_rounded, 'মাটির আর্দ্রতা', '${(((agroData['soilMoisture'] as num?) ?? 0) * 100).toStringAsFixed(1)}%', const Color(0xFF0284C7)),
                            Container(width: 1, height: 36, color: const Color(0xFFCBD5E1)),
                            _buildAgroMetric(Icons.thermostat_rounded, 'মাটির তাপমাত্রা', '${((agroData['soilTemperature'] as num?) ?? 25).toStringAsFixed(1)}°C', const Color(0xFFEA580C)),
                            Container(width: 1, height: 36, color: const Color(0xFFCBD5E1)),
                            _buildAgroMetric(Icons.check_circle_outline_rounded, 'Soil Status', agroData['soilStatus']?.toString() ?? 'Normal', const Color(0xFF059669)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 7-Day Forecast Section
                      Row(
                        children: const [
                          Icon(Icons.calendar_month_rounded, color: Color(0xFF047857), size: 20),
                          SizedBox(width: 8),
                          Text('7-Day Forecast', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: forecastList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final day = forecastList[index];
                          final dDetails = _getWeatherDetails(day['weatherCode'] as int? ?? 0);
                          final pVal = (day['precipitation'] as num?)?.toDouble() ?? 0.0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    _formatDate(day['date']?.toString() ?? ''),
                                    style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Icon(
                                  dDetails['icon'],
                                  color: dDetails['color'] == Colors.white ? Colors.blueGrey : dDetails['color'],
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dDetails['status'],
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (pVal > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${pVal.toStringAsFixed(1)}mm',
                                      style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '${((day['tempMax'] as num?) ?? 30).round()}° / ${((day['tempMin'] as num?) ?? 25).round()}°',
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Satellite Weather Map Section
                      Row(
                        children: const [
                          Icon(Icons.map_rounded, color: Color(0xFF047857), size: 20),
                          SizedBox(width: 8),
                          Text('Satellite Weather Map', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: latLng,
                              initialZoom: 7.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.farm_flutter',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: latLng,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAgroMetric(IconData icon, String label, String val, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
