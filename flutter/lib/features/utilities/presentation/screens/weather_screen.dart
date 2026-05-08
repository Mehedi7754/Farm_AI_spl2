import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'আবহাওয়ার পূর্বাভাস',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainWeatherCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('আগামী ২৪ ঘণ্টা'),
            const SizedBox(height: 16),
            _buildHourlyForecast(),
            const SizedBox(height: 32),
            _buildSectionTitle('৭ দিনের পূর্বাভাস'),
            const SizedBox(height: 16),
            _buildSevenDayForecast(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF003300), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003300).withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'বগুড়া, বাংলাদেশ',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'আজ, ২০ মে',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ভারী বৃষ্টিপাত',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.cloudy_snowing, color: Colors.white, size: 80),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '২৮°',
                    style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1),
                  ),
                  Text(
                    'আর্দ্রতা: ৮৫%',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat('অনুভূত', '৩০°', Icons.thermostat_rounded),
                _buildWeatherDivider(),
                _buildWeatherStat('বাতাস', '১২ কিমি/ঘ', Icons.air_rounded),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeatherStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }

  Widget _buildWeatherDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
    );
  }

  Widget _buildHourlyForecast() {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHourlyCard('এখন', Icons.cloudy_snowing, '২৮°', true),
          _buildHourlyCard('৬ PM', Icons.cloud_queue_rounded, '২৭°', false),
          _buildHourlyCard('৮ PM', Icons.cloudy_snowing, '২৬°', false),
          _buildHourlyCard('১০ PM', Icons.cloudy_snowing, '২৬°', false),
          _buildHourlyCard('১২ AM', Icons.wb_cloudy_rounded, '২৯°', false),
        ],
      ),
    );
  }

  Widget _buildHourlyCard(String time, IconData icon, String temp, bool isActive) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF003300) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFF0F4F7)),
        boxShadow: isActive
            ? [BoxShadow(color: const Color(0xFF003300).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(color: isActive ? Colors.white70 : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Icon(icon, color: isActive ? Colors.white : const Color(0xFF004D40), size: 24),
          const SizedBox(height: 12),
          Text(temp, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSevenDayForecast() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F4F7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          _buildForecastRow('আজ', 'ভারী বৃষ্টিপাত', '২৮°', '২২°', Icons.cloudy_snowing, true),
          _buildForecastDivider(),
          _buildForecastRow('শনিবার', 'মেঘলা আকাশ', '২৬°', '২৪°', Icons.cloud_queue_rounded, false),
          _buildForecastDivider(),
          _buildForecastRow('রবিবার', 'আংশিক মেঘলা', '৩০°', '২৪°', Icons.wb_cloudy_rounded, false),
          _buildForecastDivider(),
          _buildForecastRow('সোমবার', 'রৌদ্রোজ্জ্বল', '৩২°', '২৫°', Icons.wb_sunny_rounded, false),
          _buildForecastDivider(),
          _buildForecastRow('মঙ্গলবার', 'তীব্র রোদ', '৩৩°', '২৬°', Icons.wb_sunny_rounded, false),
          _buildForecastDivider(),
          _buildForecastRow('বুধবার', 'আংশিক মেঘলা', '৩১°', '২৫°', Icons.wb_cloudy_rounded, false),
        ],
      ),
    );
  }

  Widget _buildForecastRow(String day, String condition, String high, String low, IconData icon, bool isToday) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                color: isToday ? const Color(0xFF004D40) : const Color(0xFF1A1A1A),
              ),
            ),
          ),
          Icon(icon, size: 22, color: const Color(0xFF004D40).withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              condition,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            children: [
              Text(high, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              Text(low, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }
}
