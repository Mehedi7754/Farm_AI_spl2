import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/strings_bn.dart';

class SymptomAnalysisScreen extends StatefulWidget {
  const SymptomAnalysisScreen({super.key});

  @override
  State<SymptomAnalysisScreen> createState() => _SymptomAnalysisScreenState();
}

class _SymptomAnalysisScreenState extends State<SymptomAnalysisScreen> {
  String? _selectedAnimal;
  final List<String> _selectedSymptoms = [];

  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'জ্বর', 'icon': Icons.thermostat_rounded, 'color': const Color(0xFFFF5252)},
    {'name': 'ক্ষত', 'icon': Icons.healing_rounded, 'color': const Color(0xFF448AFF)},
    {'name': 'ফোলা', 'icon': Icons.hub_outlined, 'color': const Color(0xFF4CAF50)},
    {'name': 'ক্ষুধামন্দা', 'icon': Icons.no_food_outlined, 'color': const Color(0xFFFFAB40)},
    {'name': 'কাশি', 'icon': Icons.waves_rounded, 'color': const Color(0xFF7C4DFF)},
    {'name': 'ডায়রিয়া', 'icon': Icons.water_drop_outlined, 'color': const Color(0xFF00BCD4)},
  ];

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
        title: const Text(
          StringsBn.aiSymptom,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003300), Color(0xFFF8FBF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator Card
              _buildIndicatorCard(),
              const SizedBox(height: 28),

              // Animal Selection Card
              _buildSectionCard(
                title: StringsBn.selectAnimal,
                child: _buildAnimalDropdown(),
              ),
              const SizedBox(height: 24),

              // Symptoms Selection Card
              _buildSectionCard(
                title: StringsBn.markSymptoms,
                child: _buildSymptomGrid(),
              ),
              const SizedBox(height: 24),

              // Description Box Card
              _buildSectionCard(
                title: StringsBn.describeSymptom,
                child: _buildDescriptionBox(),
              ),
              const SizedBox(height: 24),

              // Photo Upload Area Card
              _buildSectionCard(
                title: StringsBn.addPhoto,
                child: _buildPhotoUploadArea(),
              ),
              const SizedBox(height: 36),

              // Analyze Button
              _buildAnalyzeButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003300).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildStepIndicator(),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              letterSpacing: -0.3,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: const Color(0xFFF0F4F7), width: 1),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepItem('১', StringsBn.stepAnimal, true),
        _buildStepDivider(true),
        _buildStepItem('২', StringsBn.stepSymptom, false),
        _buildStepDivider(false),
        _buildStepItem('৩', StringsBn.stepPhoto, false),
      ],
    );
  }

  Widget _buildStepItem(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF004D40) : const Color(0xFFF8F9FA),
            shape: BoxShape.circle,
            boxShadow: isActive 
              ? [BoxShadow(color: const Color(0xFF004D40).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : null,
            border: isActive ? null : Border.all(color: const Color(0xFFE0E6ED)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF7F8C8D),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF004D40) : const Color(0xFF95A5A6),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF004D40).withValues(alpha: 0.2) : const Color(0xFFECF0F1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECF0F1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAnimal,
          hint: const Text(StringsBn.chooseAnimalHint, style: TextStyle(color: Color(0xFF95A5A6), fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF004D40)),
          items: ['লক্ষ্মী (গরু)', 'লাল্টু (ষাঁড়)'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 15, fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedAnimal = val),
        ),
      ),
    );
  }

  Widget _buildSymptomGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final symptom = _symptoms[index];
        final isSelected = _selectedSymptoms.contains(symptom['name']);
        final color = symptom['color'] as Color;
        
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedSymptoms.remove(symptom['name']);
              } else {
                _selectedSymptoms.add(symptom['name']);
              }
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF004D40) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF004D40) : const Color(0xFFF0F4F7),
                width: 1.5,
              ),
              boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFF004D40).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    symptom['icon'],
                    color: isSelected ? Colors.white : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    symptom['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECF0F1)),
      ),
      child: TextField(
        maxLines: 3,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
        decoration: InputDecoration(
          hintText: StringsBn.describeHint,
          hintStyle: const TextStyle(color: Color(0xFF95A5A6), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadArea() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        painter: DashPainter(color: const Color(0xFFD1D9E6)),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF004D40), size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                StringsBn.uploadHint,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 6),
              const Text(
                StringsBn.uploadLimit,
                style: TextStyle(color: Color(0xFF95A5A6), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003300).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.push('/ai/result'),
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
        label: const Text(
          StringsBn.analyzeButton,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  final Color color;
  DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final RRect rRect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(24));
    final Path path = Path()..addRRect(rRect);

    final Path dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
