import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum AIResultState { normal, vetSoon, emergency }

class AIResultScreen extends StatelessWidget {
  final AIResultState state;

  const AIResultScreen({
    super.key,
    this.state = AIResultState.vetSoon,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিশ্লেষণের ফলাফল'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'বিশ্লেষণ সম্পন্ন',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: statusColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'আপনার গবাদি পশুর লক্ষণগুলো অস্বাভাবিক দেখাচ্ছে। দ্রুত ব্যবস্থা নেওয়া প্রয়োজন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Possible Causes
            Text(
              'সম্ভাব্য কারণ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildCauseItem(context, 'খুরারোগ (FMD)', '৮৫% মিল পাওয়া গেছে', Icons.report_problem, AppTheme.errorColor),
            _buildCauseItem(context, 'ব্যাকটেরিয়াল ইনফেকশন', '১৫% সম্ভাবনা', Icons.info_outline, Colors.blue),
            
            const SizedBox(height: 32),
            
            // Next Steps
            Text(
              'পরবর্তী পদক্ষেপ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildStepItem(context, 'আক্রান্ত পশুকে আলাদা করুন', 'অন্যান্য পশুদের সংক্রমণ থেকে রক্ষা করতে', Icons.sick_outlined),
            _buildStepItem(context, 'পরিষ্কার পানি পান করান', 'পশুকে হাইড্রেটেড রাখুন', Icons.water_drop_outlined),
            
            const SizedBox(height: 40),
            
            // Call to Action
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.videocam),
              label: const Text('টেলি-ভেটের সাথে কথা বলুন'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_hospital),
              label: const Text('নিকটস্থ হাসপাতাল খুঁজুন'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'এটি AI নির্দেশনা, চূড়ান্ত রোগ নির্ণয় নয়। যেকোনো জরুরি অবস্থায় নিকটস্থ রেজিস্টার্ড ভেটেরিনারি চিকিৎসকের পরামর্শ নিন।',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (state) {
      case AIResultState.normal: return AppTheme.successColor;
      case AIResultState.vetSoon: return AppTheme.warningColor;
      case AIResultState.emergency: return AppTheme.errorColor;
    }
  }

  String _getStatusText() {
    switch (state) {
      case AIResultState.normal: return 'সব ঠিক আছে';
      case AIResultState.vetSoon: return 'শীঘ্রই পশু চিকিৎসক দেখান';
      case AIResultState.emergency: return 'জরুরি অবস্থা!';
    }
  }

  IconData _getStatusIcon() {
    switch (state) {
      case AIResultState.normal: return Icons.check_circle_outline;
      case AIResultState.vetSoon: return Icons.warning_amber_rounded;
      case AIResultState.emergency: return Icons.emergency_share_outlined;
    }
  }

  Widget _buildCauseItem(BuildContext context, String title, String probability, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(probability),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
