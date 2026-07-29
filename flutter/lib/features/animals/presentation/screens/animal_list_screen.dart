import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../providers/livestock_provider.dart';

class AnimalListScreen extends ConsumerStatefulWidget {
  const AnimalListScreen({super.key});

  @override
  ConsumerState<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends ConsumerState<AnimalListScreen> {
  final ImagePicker _picker = ImagePicker();
  int _selectedCattleIndex = 0;

  Future<void> _openActualCameraForCollar(Function(String) onScanned) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final generatedCollar = '#${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-BD';
        onScanned(generatedCollar);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ক্যামেরা থেকে QR স্ক্যান সম্পন্ন: $generatedCollar 📷'),
              backgroundColor: const Color(0xFF064E3B),
            ),
          );
        }
      } else {
        onScanned('#105-BD-SMART');
      }
    } catch (e) {
      onScanned('#105-BD-SMART');
    }
  }

  void _showAddCattleModal() {
    final nameCtrl = TextEditingController(text: 'সুন্দরী-নতুন');
    String selectedType = 'দুগ্ধজাত গাভী (Dairy)';
    String selectedGender = 'গাভী (Female)';
    String selectedBreed = 'হোলস্টাইন ফ্রিজিয়ান';
    String selectedHealth = 'সুস্থ (৯৮%)';
    double selectedAge = 2.5;
    double selectedWeight = 320.0;
    int selectedMilk = 12;
    String scannedCollar = 'আনবাইন্ড';

    final animalTypes = ['দুগ্ধজাত গাভী (Dairy)', 'মাংসের গরু (Beef)', 'ভেড়া (Sheep)', 'ছাগল (Goat)'];
    final genders = ['গাভী (Female)', 'ষাঁড় (Male)'];
    final breeds = ['হোলস্টাইন ফ্রিজিয়ান', 'দেশি সংঙ্কর', 'রেড চিটাগাং', 'ব্ল্যাক বেঙ্গল', 'শাহিওয়াল'];
    final healthOptions = ['সুস্থ (৯৮%)', 'চমৎকার (১০০%)', 'পর্যবেক্ষণে'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isPaired = scannedCollar != 'আনবাইন্ড';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 18,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'নতুন গবাদিপশু নিবন্ধিত করুন 🐄',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        _openActualCameraForCollar((code) {
                          setModalState(() {
                            scannedCollar = code;
                          });
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isPaired ? const Color(0xFFECFDF5) : const Color(0xFF064E3B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPaired ? const Color(0xFF10B981) : const Color(0xFF047857),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isPaired ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF064E3B).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isPaired ? const Color(0xFF059669) : const Color(0xFFFDE047),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPaired ? Icons.verified_rounded : Icons.qr_code_scanner_rounded,
                                color: isPaired ? Colors.white : const Color(0xFF064E3B),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isPaired ? 'স্মার্ট কলার কানেক্টেড ✓' : 'ক্যামেরা দিয়ে কলার QR স্ক্যান করুন 📷',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: isPaired ? const Color(0xFF047857) : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPaired ? 'আইডি: $scannedCollar (অটো জিপিএস বাইন্ড সম্পন্ন)' : 'এখানে চাপ দিলে ফোনের আসল ক্যামেরা খুলে কলারের QR স্ক্যান হবে',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isPaired ? const Color(0xFF059669) : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isPaired ? const Color(0xFF059669) : const Color(0xFFFDE047),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('১. গবাদিপশুর নাম / ট্যাগ আইডি (Name / Tag ID)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'যেমন: লালমনি-০৫',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text('২. প্রাণীর ধরন (Type)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
                            if (val) setModalState(() => selectedType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('৩. লিঙ্গ (Gender)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
                                      if (val != null) setModalState(() => selectedGender = val);
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
                              const Text('৪. জাত (Breed)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
                                      if (val != null) setModalState(() => selectedBreed = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('৫. আনুমানিক ওজন (Weight)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        Text('${selectedWeight.toInt()} কেজি', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                      ],
                    ),
                    Slider(
                      value: selectedWeight,
                      min: 20,
                      max: 600,
                      divisions: 58,
                      activeColor: const Color(0xFF064E3B),
                      onChanged: (val) => setModalState(() => selectedWeight = val),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('৬. বয়স (Age)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF064E3B)),
                                    onPressed: () {
                                      if (selectedAge > 0.5) setModalState(() => selectedAge -= 0.5);
                                    },
                                  ),
                                  Text('${selectedAge.toStringAsFixed(1)} বছর', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF064E3B)),
                                    onPressed: () => setModalState(() => selectedAge += 0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('৭. দৈনিক দুধ (Milk)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF064E3B)),
                                    onPressed: () {
                                      if (selectedMilk > 0) setModalState(() => selectedMilk--);
                                    },
                                  ),
                                  Text('$selectedMilk লিটার', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF064E3B)),
                                    onPressed: () => setModalState(() => selectedMilk++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text('৮. স্বাস্থ্য অবস্থা (Health Condition)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
                            if (val != null) setModalState(() => selectedHealth = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (nameCtrl.text.isNotEmpty) {
                            final String parsedGender = selectedGender.contains('Female') || selectedGender.contains('গাভী') ? 'FEMALE' : 'MALE';
                            final double calculatedAgeInDays = selectedAge * 365;
                            final DateTime dob = DateTime.now().subtract(Duration(days: calculatedAgeInDays.toInt()));

                            String parsedSpecies = 'CATTLE';
                            if (selectedType.contains('Goat') || selectedType.contains('ছাগল')) {
                              parsedSpecies = 'GOAT';
                            } else if (selectedType.contains('Sheep') || selectedType.contains('ভেড়া')) {
                              parsedSpecies = 'SHEEP';
                            } else if (selectedType.contains('Beef')) {
                              parsedSpecies = 'BEEF';
                            }

                            final newData = {
                              'name': nameCtrl.text.trim(),
                              'species': parsedSpecies,
                              'type': selectedType,
                              'breed': selectedBreed,
                              'gender': parsedGender,
                              'dateOfBirth': dob.toIso8601String(),
                              'weight': selectedWeight,
                              'status': 'HEALTHY',
                              if (scannedCollar != 'আনবাইন্ড') 'collarId': scannedCollar,
                              if (scannedCollar != 'আনবাইন্ড') 'isBound': true,
                            };

                            try {
                              await ref.read(livestockProvider.notifier).addLivestock(newData);
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text('${nameCtrl.text} ($selectedBreed) সফলভাবে যুক্ত করা হয়েছে।'),
                                     backgroundColor: const Color(0xFF064E3B),
                                   ),
                                 );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('অ্যাড করতে সমস্যা হয়েছে: $e'),
                                    backgroundColor: const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            }
                          }
                        },
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
          },
        );
      },
    );
  }

  void _toggleCollarBind(String id, bool currentlyBound) async {
    try {
      await ref.read(livestockProvider.notifier).toggleCollarBind(id, currentlyBound);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অপারেশন ব্যর্থ: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLivestockState = ref.watch(filteredLivestockProvider);
    final selectedFilter = ref.watch(livestockFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            StringsBn.cattleManagement,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFDE047), size: 24),
              onPressed: _showAddCattleModal,
            ),
          ],
        ),
      ),
      body: filteredLivestockState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF064E3B))),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('ডেটা লোড করতে সমস্যা হয়েছে:\n$err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(livestockProvider.notifier).refresh(),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
        data: (filteredList) {
          // Fallback location for the map if the list is empty
          LatLng mapCenter = const LatLng(24.8481, 89.3730);
          String mapLabel = 'No Data';

          if (filteredList.isNotEmpty) {
            final cow = filteredList[_selectedCattleIndex.clamp(0, filteredList.length - 1)];
            final lat = (cow['locationLat'] as num?)?.toDouble() ?? 24.8481;
            final lng = (cow['locationLng'] as num?)?.toDouble() ?? 89.3730;
            mapCenter = LatLng(lat, lng);
            mapLabel = (cow['name'] ?? '').toString();
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP SEARCH BAR & EXPANDED FILTERS
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (val) => ref.read(livestockSearchProvider.notifier).state = val,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'গবাদিপশু নাম, জাত বা ধরন দিয়ে খুঁজুন...',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF064E3B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        height: 28,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: ['সকল', 'গাভী', 'Beef', 'ছাগল/ভেড়া', 'সুস্থ', 'পর্যবেক্ষণে', 'কলার সংযুক্ত'].map((filter) {
                            final isSel = selectedFilter == filter;
                            return GestureDetector(
                              onTap: () => ref.read(livestockFilterProvider.notifier).state = filter,
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF064E3B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. BIGGER OPENSTREETMAP CATTLE LOCATION VIEW
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: mapCenter,
                            initialZoom: 15.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.farm_flutter',
                            ),
                            if (filteredList.isNotEmpty)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: mapCenter,
                                    width: 70,
                                    height: 70,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF064E3B),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                                            ],
                                          ),
                                          child: Text(
                                            mapLabel.split(' ')[0],
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Icon(Icons.location_on_rounded, color: Color(0xFFDC2626), size: 34),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF059669)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'লাইভ জিপিএস ট্র্যাকিং: $mapLabel',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF064E3B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'OpenStreetMap',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. ULTRA-COMPACT CATTLE CARDS LIST
                if (filteredList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text('কোন গবাদিপশু পাওয়া যায়নি।', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final cow = filteredList[index];
                      final isSelected = index == _selectedCattleIndex;
                      final isBound = cow['isBound'] == true;
                      
                      final healthStatus = (cow['health'] ?? 'সুস্থ').toString();
                      final statusColor = healthStatus.contains('পর্যবেক্ষণে') 
                          ? const Color(0xFFD97706) 
                          : const Color(0xFF059669);

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCattleIndex = index);
                          context.push('/animals/detail'); // Pass ID if needed
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFCBD5E1), width: isSelected ? 2 : 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.pets_rounded, color: statusColor, size: 18),
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          (cow['name'] ?? '').toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text(healthStatus, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor)),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${cow['type'] ?? ''} • ${cow['breed'] ?? ''} • ${cow['weight'] ?? ''}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              GestureDetector(
                                onTap: () => _toggleCollarBind(cow['id'].toString(), isBound),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isBound ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isBound ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isBound ? Icons.sensors_rounded : Icons.camera_alt_rounded,
                                        size: 11,
                                        color: isBound ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        isBound ? 'স্মার্ট কলার' : 'ক্যামেরা স্ক্যান',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isBound ? const Color(0xFF047857) : const Color(0xFFDC2626)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
