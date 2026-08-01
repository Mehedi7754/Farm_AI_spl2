import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../../core/network/api_client.dart';
import '../providers/livestock_provider.dart';
class AnimalListScreen extends ConsumerStatefulWidget {
  const AnimalListScreen({super.key});

  @override
  ConsumerState<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends ConsumerState<AnimalListScreen> {
  final ImagePicker _picker = ImagePicker();
  int _selectedCattleIndex = 0;





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
              onPressed: () => context.push('/animals/add'),
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
          bool hasValidGps = true;

          if (filteredList.isNotEmpty) {
            final cow = filteredList[_selectedCattleIndex.clamp(0, filteredList.length - 1)];
            final smartCollar = cow['smartCollar'] as Map<String, dynamic>?;
            final lat = (smartCollar?['lastLatitude'] as num?)?.toDouble() 
                ?? (cow['locationLat'] as num?)?.toDouble() 
                ?? (cow['deviceLat'] as num?)?.toDouble() 
                ?? 0.0;
            final lng = (smartCollar?['lastLongitude'] as num?)?.toDouble() 
                ?? (cow['locationLng'] as num?)?.toDouble() 
                ?? (cow['deviceLng'] as num?)?.toDouble() 
                ?? 0.0;
            
            final isBound = cow['isBound'] == true || smartCollar != null;

            if ((lat == 0.0 || lng == 0.0) && isBound) {
              hasValidGps = false;
              mapCenter = const LatLng(23.8103, 90.4125);
            } else if (lat != 0.0 && lng != 0.0) {
              hasValidGps = true;
              mapCenter = LatLng(lat, lng);
            }
            
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
                              urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
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
                                    border: Border.all(color: hasValidGps ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        hasValidGps ? Icons.gps_fixed_rounded : Icons.satellite_alt_rounded,
                                        size: 14,
                                        color: hasValidGps ? const Color(0xFF059669) : const Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasValidGps ? 'লাইভ জিপিএস ট্র্যাকিং: $mapLabel' : 'জিপিএস লক খোঁজা হচ্ছে... ($mapLabel)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: hasValidGps ? const Color(0xFF0F172A) : const Color(0xFF92400E),
                                        ),
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
                                    'Live GPS Map',
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
                      final smartCollar = cow['smartCollar'] as Map<String, dynamic>?;
                      final isBound = cow['isBound'] == true || smartCollar != null;
                      
                      final healthStatus = (cow['health'] ?? 'সুস্থ').toString();
                      final statusColor = healthStatus.contains('পর্যবেক্ষণে') 
                          ? const Color(0xFFD97706) 
                          : const Color(0xFF059669);

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCattleIndex = index);
                          context.push('/animals/detail', extra: cow);
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
                                onTap: () {
                                  if (isBound) {
                                    context.push('/smart-collar');
                                  } else {
                                    _toggleCollarBind(cow['id'].toString(), isBound);
                                  }
                                },
                                child: () {
                                  final smartCollar = cow['smartCollar'] as Map<String, dynamic>?;
                                  final isOnline = smartCollar?['isOnline'] == true;

                                  final badgeBg = !isBound 
                                      ? const Color(0xFFFEF2F2)
                                      : (isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB));
                                  final badgeBorder = !isBound 
                                      ? const Color(0xFFFCA5A5)
                                      : (isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A));
                                  final iconColor = !isBound 
                                      ? const Color(0xFFDC2626)
                                      : (isOnline ? const Color(0xFF059669) : const Color(0xFFD97706));
                                  final textColor = !isBound 
                                      ? const Color(0xFFDC2626)
                                      : (isOnline ? const Color(0xFF047857) : const Color(0xFF92400E));
                                  final labelText = !isBound 
                                      ? 'ক্যামেরা স্ক্যান'
                                      : (isOnline ? 'স্মার্ট কলার (অনলাইন 🟢)' : 'কলার অফলাইন 🔴');
                                  final iconData = !isBound
                                      ? Icons.camera_alt_rounded
                                      : (isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: badgeBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(iconData, size: 11, color: iconColor),
                                        const SizedBox(width: 2),
                                        Text(
                                          labelText,
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                      ],
                                    ),
                                  );
                                }(),
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
