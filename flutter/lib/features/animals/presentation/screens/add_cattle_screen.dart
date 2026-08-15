import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../../core/network/api_client.dart';
import '../providers/livestock_provider.dart';

class AddCattleScreen extends ConsumerStatefulWidget {
  const AddCattleScreen({super.key});

  @override
  ConsumerState<AddCattleScreen> createState() => _AddCattleScreenState();
}

class _AddCattleScreenState extends ConsumerState<AddCattleScreen> {
  final nameCtrl = TextEditingController();
  final deviceCodeCtrl = TextEditingController();

  bool isVerifying = false;
  bool isVerified = false;
  double? deviceLat;
  double? deviceLng;
  bool hasGpsLock = false;
  bool deviceIsOnline = false;
  int deviceBattery = 100;

  String selectedType = 'দুগ্ধজাত গাভী (Dairy)';
  String selectedGender = 'গাভী (Female)';
  String selectedBreed = 'হোলস্টাইন ফ্রিজিয়ান';
  String selectedHealth = 'সুস্থ (৯৮%)';
  String selectedLactation = 'দুগ্ধবতী (Lactating)';
  double selectedAge = 2.5;
  double selectedWeight = 320.0;
  int selectedMilk = 12;

  final animalTypes = ['দুগ্ধজাত গাভী (Dairy)', 'মাংসের গরু (Beef)', 'ভেড়া (Sheep)', 'ছাগল (Goat)'];
  final genders = ['গাভী (Female)', 'ষাঁড় (Male)'];
  final breeds = ['হোলস্টাইন ফ্রিজিয়ান', 'দেশি সংঙ্কর', 'রেড চিটাগাং', 'ব্ল্যাক বেঙ্গল', 'শাহিওয়াল'];
  final healthOptions = ['সুস্থ (৯৮%)', 'চমৎকার (১০০%)', 'পর্যবেক্ষণে'];
  final lactationStages = ['দুগ্ধবতী (Lactating)', 'গর্ভবতী (Pregnant)', 'শুষ্ক / সাধারণ (Dry)'];

  @override
  void dispose() {
    nameCtrl.dispose();
    deviceCodeCtrl.dispose();
    super.dispose();
  }

  void _openQrScanner() async {
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (status.isDenied || status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ক্যামেরা ব্যবহারের অনুমতি প্রয়োজন QR কোড স্ক্যান করতে।'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        bool isDetected = false;
        final scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        );

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.70,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: MobileScanner(
                      controller: scannerController,
                      errorBuilder: (context, error, child) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  'ক্যামেরা ওপেন করা সম্ভব হয়নি বা ক্যামেরা ব্যস্ত।',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    scannerController.dispose();
                                    Navigator.pop(modalCtx);
                                    deviceCodeCtrl.text = 'DEV-124';
                                    _verifyDevice();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF064E3B)),
                                  child: const Text('টেস্ট কোড DEV-124 ব্যবহার করুন', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onDetect: (capture) {
                        if (isDetected) return;
                        for (final barcode in capture.barcodes) {
                          final val = barcode.rawValue;
                          if (val != null && val.isNotEmpty) {
                            isDetected = true;
                            String code = val.trim();
                            if (code.contains('collar/')) {
                              code = code.split('collar/').last;
                            } else if (code.contains('DEV-')) {
                              final m = RegExp(r'DEV-[A-Za-z0-9_-]+').firstMatch(code);
                              if (m != null) code = m.group(0)!;
                            }
                            scannerController.dispose();
                            Navigator.pop(modalCtx);
                            deviceCodeCtrl.text = code;
                            _verifyDevice();
                            break;
                          }
                        }
                      },
                    ),
                  ),

                  // Target Overlay Frame
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF10B981), width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  // Header
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'কলার QR কোড স্ক্যান করুন',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () {
                            scannerController.dispose();
                            Navigator.pop(modalCtx);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom demo buttons
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ক্যামেরা ফ্রেমের মাঝে কলার QR কোডটি ধরুন',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                scannerController.dispose();
                                Navigator.pop(modalCtx);
                                deviceCodeCtrl.text = 'DEV-124';
                                _verifyDevice();
                              },
                              icon: const Icon(Icons.sensors_rounded, size: 14, color: Colors.white),
                              label: const Text('টেস্ট DEV-124', style: TextStyle(fontSize: 11, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF064E3B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                scannerController.dispose();
                                Navigator.pop(modalCtx);
                                deviceCodeCtrl.text = 'DEV-882';
                                _verifyDevice();
                              },
                              icon: const Icon(Icons.sensors_rounded, size: 14, color: Colors.white),
                              label: const Text('টেস্ট DEV-882', style: TextStyle(fontSize: 11, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047857),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _verifyDevice() async {
    final code = deviceCodeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      isVerifying = true;
    });

    try {
      final result = await ApiClient.getDeviceLocation(code);
      if (result != null) {
        final isOnline = result['isOnline'] == true;
        setState(() {
          deviceIsOnline = isOnline;
          deviceBattery = (result['batteryLevel'] as num?)?.toInt() ?? 100;
          deviceLat = (result['latitude'] as num?)?.toDouble() ?? 22.85384;
          deviceLng = (result['longitude'] as num?)?.toDouble() ?? 91.094149;
          hasGpsLock = (deviceLat != 0.0 && deviceLat != null && deviceLng != 0.0 && deviceLng != null);
          isVerified = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOnline ? 'স্মার্ট কলার $code সফলভাবে অনলাইন এবং ভেরিফাই হয়েছে! 🛰️' : 'ডিভাইসটি পাওয়া গিয়েছে কিন্তু অফলাইন আছে।'),
              backgroundColor: isOnline ? const Color(0xFF064E3B) : const Color(0xFFD97706),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            isVerified = false;
            deviceIsOnline = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ডিভাইস "$code" পাওয়া যায়নি। অনুগ্রহ করে কোড চেক করুন।'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ভেরিফিকেশন ত্রুটি: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  Future<void> _saveCattle() async {
    if (nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে গবাদিপশুর নাম প্রদান করুন।'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final String parsedGender = selectedGender.contains('Female') || selectedGender.contains('গাভী') ? 'FEMALE' : 'MALE';
    final double calculatedAgeInDays = selectedAge * 365;
    final DateTime dob = DateTime.now().subtract(Duration(days: calculatedAgeInDays.toInt()));

    String parsedSpecies = 'COW';
    if (selectedType.contains('Goat') || selectedType.contains('ছাগল')) {
      parsedSpecies = 'GOAT';
    } else if (selectedType.contains('Sheep') || selectedType.contains('ভেড়া')) {
      parsedSpecies = 'SHEEP';
    }

    final isPregnant = selectedLactation.contains('গর্ভবতী');

    final newData = {
      'name': nameCtrl.text.trim(),
      'species': parsedSpecies,
      'breed': selectedBreed,
      'gender': parsedGender,
      'dateOfBirth': dob.toIso8601String(),
      'weight': selectedWeight,
      'status': selectedHealth.contains('পর্যবেক্ষণে') ? 'MONITORED' : 'HEALTHY',
      'lactationStage': selectedLactation.contains('দুগ্ধবতী') ? 'LACTATING' : (isPregnant ? 'PREGNANT' : 'DRY'),
      'isPregnant': isPregnant,
      'dailyMilkYield': selectedMilk.toDouble(),
      if (isVerified) 'collarId': deviceCodeCtrl.text.trim(),
      if (isVerified) 'isBound': true,
    };

    try {
      await ref.read(livestockProvider.notifier).addLivestock(newData);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${nameCtrl.text} ($selectedBreed) সফলভাবে যুক্ত করা হয়েছে। 🐄'),
            backgroundColor: const Color(0xFF064E3B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('যুক্ত করতে সমস্যা হয়েছে: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'নতুন গবাদিপশু যুক্ত করুন',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Device Verification & QR
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sensors_rounded, color: Color(0xFF064E3B), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'স্মার্ট কলার সংযোগ (Smart Collar)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      // QR Scan Action
                      ElevatedButton.icon(
                        onPressed: _openQrScanner,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 13, color: Colors.white),
                        label: const Text('QR স্ক্যান', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('স্মার্ট কলার আইডি (Device Code)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: deviceCodeCtrl,
                          enabled: !isVerified,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: 'যেমন: DEV-124 বা QR স্ক্যান করুন',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF059669))),
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF475569)),
                          onPressed: () {
                            setState(() {
                              isVerified = false;
                              deviceIsOnline = false;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick test chip shortcuts
                  if (!isVerified) ...[
                    Row(
                      children: [
                        const Text('দ্রুত টেস্ট: ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            deviceCodeCtrl.text = 'DEV-124';
                            _verifyDevice();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text('DEV-124', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            deviceCodeCtrl.text = 'DEV-882';
                            _verifyDevice();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text('DEV-882', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: isVerifying ? null : _verifyDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isVerifying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('যাচাই করুন (Verify)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  if (isVerified && deviceLat != null && deviceLng != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: deviceIsOnline ? Colors.green : Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              deviceIsOnline ? 'ডিভাইস অনলাইন (Active) 🟢' : 'ডিভাইস অফলাইন 🔴',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deviceIsOnline ? Colors.green : Colors.orange),
                            ),
                          ],
                        ),
                        Text(
                          '🔋 ব্যাটারি: $deviceBattery%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(deviceLat!, deviceLng!),
                            initialZoom: 14.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(deviceLat!, deviceLng!),
                                  child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 28),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(hasGpsLock ? Icons.gps_fixed_rounded : Icons.satellite_alt_rounded, size: 14, color: hasGpsLock ? const Color(0xFF059669) : const Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          hasGpsLock ? 'জিপিএস সিগন্যাল সচল 🛰️' : 'GPS সিগন্যাল পাওয়া যাচ্ছে না',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasGpsLock ? const Color(0xFF059669) : const Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Animal Data Form
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('গবাদিপশুর নাম / ট্যাগ আইডি (Name / Tag ID)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'যেমন: সুন্দরী-০১',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('প্রাণীর ধরন (Type)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: animalTypes.map((type) {
                      final isSel = selectedType == type;
                      return ChoiceChip(
                        selected: isSel,
                        label: Text(type, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : const Color(0xFF0F172A))),
                        selectedColor: const Color(0xFF064E3B),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          if (val) setState(() => selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('লিঙ্গ (Gender)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedGender,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => selectedGender = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('জাত (Breed)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedBreed,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  items: breeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => selectedBreed = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('দুগ্ধ/প্রজনন অবস্থা', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedLactation,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  items: lactationStages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => selectedLactation = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('স্বাস্থ্য অবস্থা (Health)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedHealth,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  items: healthOptions.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => selectedHealth = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('আনুমানিক ওজন (Weight)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      Text('${selectedWeight.toInt()} কেজি', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    ],
                  ),
                  Slider(
                    value: selectedWeight,
                    min: 20,
                    max: 600,
                    divisions: 58,
                    activeColor: const Color(0xFF064E3B),
                    onChanged: (val) => setState(() => selectedWeight = val),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('বয়স (Age)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF064E3B)),
                                  onPressed: () {
                                    if (selectedAge > 0.5) setState(() => selectedAge -= 0.5);
                                  },
                                ),
                                Text('${selectedAge.toStringAsFixed(1)} বছর', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF064E3B)),
                                  onPressed: () {
                                    if (selectedAge < 20) setState(() => selectedAge += 0.5);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('দৈনিক দুধ উৎপাদন (Litre)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF064E3B)),
                                  onPressed: () {
                                    if (selectedMilk > 0) setState(() => selectedMilk -= 1);
                                  },
                                ),
                                Text('$selectedMilk লিটার', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF064E3B)),
                                  onPressed: () {
                                    if (selectedMilk < 100) setState(() => selectedMilk += 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saveCattle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                label: const Text('সংরক্ষণ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
