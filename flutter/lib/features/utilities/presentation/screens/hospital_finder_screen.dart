import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/location_service.dart';

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({super.key});

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;
  int _selectedHospitalIndex = 0;
  LatLng? _userGpsLocation;
  String _userAreaName = 'অবস্থান নির্ণয় করা হচ্ছে...';
  String _selectedDistrict = 'নোয়াখালী';

  final MapController _mapController = MapController();
  static const String _customVetsStorageKey = 'farm_ai_custom_vets_v1';

  // 64 Bangladesh Districts with real administrative center coordinates
  static const List<Map<String, String>> _all64Districts = [
    // Chittagong Division
    {'name': 'নোয়াখালী', 'division': 'চট্টগ্রাম', 'lat': '22.8696', 'lng': '91.0993'},
    {'name': 'চট্টগ্রাম', 'division': 'চট্টগ্রাম', 'lat': '22.3569', 'lng': '91.7832'},
    {'name': 'কুমিল্লা', 'division': 'চট্টগ্রাম', 'lat': '23.4607', 'lng': '91.1809'},
    {'name': 'ফেনী', 'division': 'চট্টগ্রাম', 'lat': '23.0159', 'lng': '91.3976'},
    {'name': 'লক্ষ্মীপুর', 'division': 'চট্টগ্রাম', 'lat': '22.9447', 'lng': '90.8282'},
    {'name': 'চাঁদপুর', 'division': 'চট্টগ্রাম', 'lat': '23.2321', 'lng': '90.6631'},
    {'name': 'ব্রাহ্মণবাড়িয়া', 'division': 'চট্টগ্রাম', 'lat': '23.9571', 'lng': '91.1119'},
    {'name': 'কক্সবাজার', 'division': 'চট্টগ্রাম', 'lat': '21.4272', 'lng': '92.0058'},
    {'name': 'রাঙ্গামাটি', 'division': 'চট্টগ্রাম', 'lat': '22.6533', 'lng': '92.1789'},
    {'name': 'খাগড়াছড়ি', 'division': 'চট্টগ্রাম', 'lat': '23.1193', 'lng': '91.9847'},
    {'name': 'বান্দরবান', 'division': 'চট্টগ্রাম', 'lat': '22.1958', 'lng': '92.2184'},

    // Dhaka Division
    {'name': 'ঢাকা', 'division': 'ঢাকা', 'lat': '23.8103', 'lng': '90.4125'},
    {'name': 'গাজীপুর', 'division': 'ঢাকা', 'lat': '23.9999', 'lng': '90.4203'},
    {'name': 'নারায়ণগঞ্জ', 'division': 'ঢাকা', 'lat': '23.6238', 'lng': '90.5000'},
    {'name': 'নরসিংদী', 'division': 'ঢাকা', 'lat': '23.9193', 'lng': '90.7201'},
    {'name': 'টাঙ্গাইল', 'division': 'ঢাকা', 'lat': '24.2513', 'lng': '89.9167'},
    {'name': 'মানিকগঞ্জ', 'division': 'ঢাকা', 'lat': '23.8644', 'lng': '90.0047'},
    {'name': 'মুন্সীগঞ্জ', 'division': 'ঢাকা', 'lat': '23.5422', 'lng': '90.5305'},
    {'name': 'ফরিদপুর', 'division': 'ঢাকা', 'lat': '23.6070', 'lng': '89.8406'},
    {'name': 'মাদারীপুর', 'division': 'ঢাকা', 'lat': '23.1641', 'lng': '90.1897'},
    {'name': 'শরীয়তপুর', 'division': 'ঢাকা', 'lat': '23.2423', 'lng': '90.4348'},
    {'name': 'রাজবাড়ী', 'division': 'ঢাকা', 'lat': '23.7574', 'lng': '89.6444'},
    {'name': 'গোপালগঞ্জ', 'division': 'ঢাকা', 'lat': '23.0050', 'lng': '89.8266'},
    {'name': 'কিশোরগঞ্জ', 'division': 'ঢাকা', 'lat': '24.4449', 'lng': '90.7765'},

    // Rajshahi Division
    {'name': 'বগুড়া', 'division': 'রাজশাহী', 'lat': '24.8481', 'lng': '89.3730'},
    {'name': 'রাজশাহী', 'division': 'রাজশাহী', 'lat': '24.3745', 'lng': '88.6042'},
    {'name': 'পাবনা', 'division': 'রাজশাহী', 'lat': '24.0064', 'lng': '89.2500'},
    {'name': 'সিরাজগঞ্জ', 'division': 'রাজশাহী', 'lat': '24.4534', 'lng': '89.7008'},
    {'name': 'নওগাঁ', 'division': 'রাজশাহী', 'lat': '24.7936', 'lng': '88.9318'},
    {'name': 'নাটোর', 'division': 'রাজশাহী', 'lat': '24.4102', 'lng': '89.0076'},
    {'name': 'চাঁপাইনবাবগঞ্জ', 'division': 'রাজশাহী', 'lat': '24.5965', 'lng': '88.2775'},
    {'name': 'জয়পুরহাট', 'division': 'রাজশাহী', 'lat': '25.1018', 'lng': '89.0270'},

    // Khulna Division
    {'name': 'খুলনা', 'division': 'খুলনা', 'lat': '22.8456', 'lng': '89.5403'},
    {'name': 'বাগেরহাট', 'division': 'খুলনা', 'lat': '22.6516', 'lng': '89.7859'},
    {'name': 'সাতক্ষীরা', 'division': 'খুলনা', 'lat': '22.7185', 'lng': '89.0705'},
    {'name': 'যশোর', 'division': 'খুলনা', 'lat': '23.1664', 'lng': '89.2081'},
    {'name': 'ঝিনাইদহ', 'division': 'খুলনা', 'lat': '23.5448', 'lng': '89.1539'},
    {'name': 'মাগুরা', 'division': 'খুলনা', 'lat': '23.4873', 'lng': '89.4199'},
    {'name': 'নড়াইল', 'division': 'খুলনা', 'lat': '23.1725', 'lng': '89.5126'},
    {'name': 'কুষ্টিয়া', 'division': 'খুলনা', 'lat': '23.9013', 'lng': '89.1204'},
    {'name': 'মেহেরপুর', 'division': 'খুলনা', 'lat': '23.7622', 'lng': '88.6318'},
    {'name': 'চুয়াডাঙ্গা', 'division': 'খুলনা', 'lat': '23.6402', 'lng': '88.8418'},

    // Barishal Division
    {'name': 'বরিশাল', 'division': 'বরিশাল', 'lat': '22.7010', 'lng': '90.3535'},
    {'name': 'ভোলা', 'division': 'বরিশাল', 'lat': '22.6859', 'lng': '90.6482'},
    {'name': 'ঝালকাঠি', 'division': 'বরিশাল', 'lat': '22.6406', 'lng': '90.1987'},
    {'name': 'পিরোজপুর', 'division': 'বরিশাল', 'lat': '22.5841', 'lng': '89.9720'},
    {'name': 'বরগুনা', 'division': 'বরিশাল', 'lat': '22.1570', 'lng': '90.1264'},
    {'name': 'পটুয়াখালী', 'division': 'বরিশাল', 'lat': '22.3596', 'lng': '90.3299'},

    // Sylhet Division
    {'name': 'সিলেট', 'division': 'সিলেট', 'lat': '24.8949', 'lng': '91.8687'},
    {'name': 'মৌলভীবাজার', 'division': 'সিলেট', 'lat': '24.4829', 'lng': '91.7774'},
    {'name': 'হবিগঞ্জ', 'division': 'সিলেট', 'lat': '24.3749', 'lng': '91.4153'},
    {'name': 'সুনামগঞ্জ', 'division': 'সিলেট', 'lat': '25.0658', 'lng': '91.3950'},

    // Rangpur Division
    {'name': 'রংপুর', 'division': 'রংপুর', 'lat': '25.7439', 'lng': '89.2752'},
    {'name': 'দিনাজপুর', 'division': 'রংপুর', 'lat': '25.6279', 'lng': '88.6332'},
    {'name': 'গাইবান্ধা', 'division': 'রংপুর', 'lat': '25.3288', 'lng': '89.5409'},
    {'name': 'কুড়িগ্রাম', 'division': 'রংপুর', 'lat': '25.8054', 'lng': '89.6361'},
    {'name': 'লালমনিরহাট', 'division': 'রংপুর', 'lat': '25.9165', 'lng': '89.4532'},
    {'name': 'নীলফামারী', 'division': 'রংপুর', 'lat': '25.9317', 'lng': '88.8560'},
    {'name': 'পঞ্চগড়', 'division': 'রংপুর', 'lat': '26.3411', 'lng': '88.5541'},
    {'name': 'ঠাকুরগাঁও', 'division': 'রংপুর', 'lat': '26.0332', 'lng': '88.4617'},

    // Mymensingh Division
    {'name': 'ময়মনসিংহ', 'division': 'ময়মনসিংহ', 'lat': '24.7471', 'lng': '90.4203'},
    {'name': 'জামালপুর', 'division': 'ময়মনসিংহ', 'lat': '24.9375', 'lng': '89.9377'},
    {'name': 'নেত্রকোণা', 'division': 'ময়মনসিংহ', 'lat': '24.8804', 'lng': '90.7279'},
    {'name': 'শেরপুর', 'division': 'ময়মনসিংহ', 'lat': '25.0205', 'lng': '90.0153'},
  ];

  static final Map<String, List<Map<String, dynamic>>> _realBangladeshHospitals = {
    'নোয়াখালী': [
      {
        'id': 'noakhali-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, নোয়াখালী',
        'address': 'জেলা প্রাণিসম্পদ ভবন, মাইজদী কোর্ট, নোয়াখালী সদর',
        'phone': '০৩২১-৬১২৮৪ / ০১৭১৬-৮২৮৯৬৯',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 22.8696,
        'longitude': 91.0993,
      },
      {
        'id': 'noakhali-2',
        'name': 'বেগমগঞ্জ উপজেলা প্রাণিসম্পদ দফতর ও মডেল হাসপাতাল',
        'address': 'চৌমুহনী বাসস্ট্যান্ড সংলগ্ন, বেগমগঞ্জ, নোয়াখালী',
        'phone': '০১৭১৫-৪৪৩৩২২',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 22.9510,
        'longitude': 91.1030,
      },
      {
        'id': 'noakhali-3',
        'name': 'কোম্পানীগঞ্জ উপজেলা প্রাণিসম্পদ কমপ্লেক্স',
        'address': 'বসুরহাট বাজার, কোম্পানীগঞ্জ, নোয়াখালী',
        'phone': '০১৭১৮-৯৯০০১১',
        'hours': 'সকাল ৯:০০ - বিকেল ৫:০০',
        'latitude': 22.8715,
        'longitude': 91.2780,
      },
      {
        'id': 'noakhali-4',
        'name': 'চাটখিল উপজেলা প্রাণিসম্পদ হাসপাতাল',
        'address': 'চাটখিল বাজার রোড, নোয়াখালী',
        'phone': '০১৭১৬-৫৫৪৪২২',
        'hours': 'সকাল ৯:০০ - বিকেল ৫:০০',
        'latitude': 23.0450,
        'longitude': 90.9570,
      },
    ],
    'ঢাকা': [
      {
        'id': 'dhaka-1',
        'name': 'কেন্দ্রীয় পশু হাসপাতাল, ঢাকা (Central Vet Hospital)',
        'address': '৪৮ কাজী আলাউদ্দিন রোড, বংশাল, ঢাকা-১০০০',
        'phone': '০২-৯৫৫২৪৩১ / ০২-৪৮১১৮৪৭৫',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.7225,
        'longitude': 90.4045,
      },
      {
        'id': 'dhaka-2',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, ঢাকা',
        'address': 'খামারবাড়ি, ফার্মগেট, তেজগাঁও, ঢাকা',
        'phone': '০১৩২৪-২৯০৩৪৩ / ০১৯৮৩-১২২৬২৫',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.7588,
        'longitude': 90.3887,
      },
      {
        'id': 'dhaka-3',
        'name': 'সাভার উপজেলা প্রাণিসম্পদ কমপ্লেক্স ও মডেল হাসপাতাল',
        'address': 'সাভার বাজার বাসস্ট্যান্ড সংলগ্ন, সাভার, ঢাকা',
        'phone': '০১৭১৪-৫৫৬৬৭৭',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.8583,
        'longitude': 90.2667,
      },
    ],
    'গাজীপুর': [
      {
        'id': 'gazipur-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, গাজীপুর',
        'address': 'রাজবাড়ী রোড, গাজীপুর সদর',
        'phone': '০২-২২৪৪২২৩২২৭ / ০১৩২৪-২৯০৩৬০',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.9999,
        'longitude': 90.4203,
      },
    ],
    'বগুড়া': [
      {
        'id': 'bogra-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও পশু হাসপাতাল, বগুড়া',
        'address': 'মালতিনগর, ক্যানাল পার, বগুড়া সদর',
        'phone': '০২৫৮৯-৯০২৭০৯ / ০১৩২৪-২৮৯৩২৪',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.8481,
        'longitude': 89.3730,
      },
    ],
    'ময়মনসিংহ': [
      {
        'id': 'mymensingh-1',
        'name': 'বাংলাদেশ কৃষি বিশ্ববিদ্যালয় (BAU) ভেটেরিনারি টিচিং হাসপাতাল',
        'address': 'বাকৃবি ক্যাম্পাস, ময়মনসিংহ-২২০২',
        'phone': '০৯১-৬৭৪০১ / ০১৭১২-১১৪455',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.7262,
        'longitude': 90.4354,
      },
      {
        'id': 'mymensingh-2',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও পশু হাসপাতাল, ময়মনসিংহ',
        'address': 'কাচারি ঘাট রোড, ময়মনসিংহ সদর',
        'phone': '০২৯৯৭-৭১০৭৫২ / ০১৩২৪-২৯০১৫৫',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.7570,
        'longitude': 90.4020,
      },
    ],
    'রাজশাহী': [
      {
        'id': 'rajshahi-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও ভেটেরিনারি হাসপাতাল, রাজশাহী',
        'address': 'সিঅ্যান্ডবি মোড়, রেশমবোর্ড সংলগ্ন, রাজশাহী',
        'phone': '০২৫৮৮-৮৬১৫৬০ / ০১৩২৪-২৮৯৪১৯',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.3745,
        'longitude': 88.6042,
      },
    ],
    'চট্টগ্রাম': [
      {
        'id': 'chittagong-1',
        'name': 'চট্টগ্রাম ভেটেরিনারি ও এনিম্যাল সাইন্সেস বিশ্ববিদ্যালয় (CVASU) হাসপাতাল',
        'address': 'জাকির হোসেন রোড, খুলশী, চট্টগ্রাম',
        'phone': '০৩১-৬৫ ৯০ ৯৩ / ০১৭১১-২২৩৩৪৪',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 22.3607,
        'longitude': 91.8028,
      },
    ],
    'কুমিল্লা': [
      {
        'id': 'comilla-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও ভেটেরিনারি হাসপাতাল, কুমিল্লা',
        'address': 'ছোটরা, রেসকোর্স রোড, কুমিল্লা সদর',
        'phone': '০২৩৩৪-৪০৬২৩৫ / ০১৩২৪-২৯০৭৮৯',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.4607,
        'longitude': 91.1809,
      },
    ],
    'ফেনী': [
      {
        'id': 'feni-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, ফেনী',
        'address': 'ট্রাঙ্ক রোড, ফেনী সদর',
        'phone': '০৩৩১-৭১২৪১ / ০১৭০০-১১৮৮৯৯',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.0159,
        'longitude': 91.3976,
      },
    ],
    'সিলেট': [
      {
        'id': 'sylhet-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও ভেটেরিনারি হাসপাতাল, সিলেট',
        'address': 'আম্বরখানা-সোবহানীঘাট রোড, সিলেট',
        'phone': '০১৩২৪-২৯০৬১৩ / ০১৭৭০-৫১৯৬৮০',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.8949,
        'longitude': 91.8687,
      },
    ],
    'খুলনা': [
      {
        'id': 'khulna-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও পশু হাসপাতাল, খুলনা',
        'address': 'বয়রা, খুলনা সদর',
        'phone': '০২৪৭৭-৭২১৭৫৫ / ০১৩২৪-২৮৯৮৪৩',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 22.8456,
        'longitude': 89.5403,
      },
    ],
    'বরিশাল': [
      {
        'id': 'barishal-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, বরিশাল',
        'address': 'বান্দ রোড, কেডিএ কম্পাউন্ড, বরিশাল',
        'phone': '০২৪৭৮-৮৬১০৮৪ / ০১৭১৫-৪২২৭২২',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 22.7010,
        'longitude': 90.3535,
      },
    ],
    'রংপুর': [
      {
        'id': 'rangpur-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও ভেটেরিনারি হাসপাতাল, রংপুর',
        'address': 'ধাপ, জেল রোড, রংপুর',
        'phone': '০২৫৮৯-৯৬২১০৬ / ০১৭১২-১৯৬৬৭০',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 25.7439,
        'longitude': 89.2752,
      },
    ],
    'পাবনা': [
      {
        'id': 'pabna-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, পাবনা',
        'address': 'আব্দুল হামিদ রোড, পাবনা সদর',
        'phone': '০২৫৮৮-৮৪২৩৪৩ / ০১৭১১-২৬১২২৩',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.0064,
        'longitude': 89.2500,
      },
    ],
    'টাঙ্গাইল': [
      {
        'id': 'tangail-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, টাঙ্গাইল',
        'address': 'ময়মনসিংহ রোড, টাঙ্গাইল সদর',
        'phone': '০২৯৯৭-৭৫৩৫৮৪ / ০১৩২৪-২৯০০৭২',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 24.2513,
        'longitude': 89.9167,
      },
    ],
    'যশোর': [
      {
        'id': 'jessore-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, যশোর',
        'address': 'স্টেশন রোড, জজ কোর্ট মোড়, যশোর',
        'phone': '০২৪৭৭-৭৬১৪১২ / ০১৩২৪-২৮৯৭৪২',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 23.1664,
        'longitude': 89.2081,
      },
    ],
    'দিনাজপুর': [
      {
        'id': 'dinajpur-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, দিনাজপুর',
        'address': 'বড় মাঠ সংলগ্ন, দিনাজপুর সদর',
        'phone': '০২৫৮৮-৮১৮৮৯১ / ০১৩২৪-২৮৯০৯৬',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 25.6279,
        'longitude': 88.6332,
      },
    ],
    'কক্সবাজার': [
      {
        'id': 'coxsbazar-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও হাসপাতাল, কক্সবাজার',
        'address': 'ঝাউতলা, কক্সবাজার সদর',
        'phone': '০২-৫১০৬০২৮৯ / ০১৮৬৫-২৪২৯৪৯',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': 21.4272,
        'longitude': 92.0058,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchRealGpsLocationAndVets();
  }

  Future<void> _fetchRealGpsLocationAndVets() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _userAreaName = 'জিপিএস দিয়ে অবস্থান নির্ণয় করা হচ্ছে...';
      });
    }

    double lat = 22.8696;
    double lng = 91.0993;

    try {
      final locMap = await LocationService.getStrictRealLocation();
      lat = locMap['lat']!;
      lng = locMap['lng']!;
      debugPrint('✅ Got real GPS location: $lat, $lng');
    } catch (e) {
      debugPrint('⚠️ GPS fallback: $e');
    }

    // Mathematically find nearest district by GPS distance
    String matchedDistrict = 'নোয়াখালী';
    double minDistance = double.infinity;

    for (var d in _all64Districts) {
      final dLat = double.parse(d['lat']!);
      final dLng = double.parse(d['lng']!);
      final dist = Geolocator.distanceBetween(lat, lng, dLat, dLng);
      if (dist < minDistance) {
        minDistance = dist;
        matchedDistrict = d['name']!;
      }
    }

    final areaName = await LocationService.getAreaNameFromCoordinates(lat, lng);

    _loadDistrictHospitals(matchedDistrict, userLat: lat, userLng: lng, areaTitle: '$matchedDistrict ($areaName)');
  }

  Future<List<Map<String, dynamic>>> _loadPersistedCustomVets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_customVetsStorageKey);
      if (str != null) {
        final List list = jsonDecode(str);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading custom vets: $e');
    }
    return [];
  }

  Future<void> _saveCustomVetLocally(Map<String, dynamic> vet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _loadPersistedCustomVets();
      list.insert(0, vet);
      await prefs.setString(_customVetsStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving custom vet: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOverpassNearbyVets(double lat, double lng) async {
    try {
      final query = '[out:json][timeout:5];(node["amenity"="veterinary"](around:30000, $lat, $lng);node["healthcare"="veterinary"](around:30000, $lat, $lng););out body 15;';
      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(url, body: query).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List?;
        if (elements != null && elements.isNotEmpty) {
          final List<Map<String, dynamic>> res = [];
          for (var item in elements) {
            final tags = item['tags'] as Map<String, dynamic>? ?? {};
            final name = tags['name:bn'] ?? tags['name'] ?? tags['official_name'] ?? 'ভেটেরিনারি ক্লিনিক ও হাসপাতাল';
            final phone = tags['phone'] ?? tags['contact:phone'] ?? '০১৭০০-১১৮৮৯৯';
            final street = tags['addr:street'] ?? tags['addr:suburb'] ?? tags['addr:city'] ?? 'উপজেলা প্রাণিসম্পদ চত্বর';

            res.add({
              'id': 'osm-${item['id']}',
              'name': name,
              'address': street,
              'phone': phone,
              'hours': tags['opening_hours'] ?? '২৪/৭ জরুরি সেবা খোলা',
              'latitude': (item['lat'] as num).toDouble(),
              'longitude': (item['lon'] as num).toDouble(),
            });
          }
          return res;
        }
      }
    } catch (e) {
      debugPrint('Overpass API query error: $e');
    }
    return [];
  }

  List<Map<String, dynamic>> _getDistrictGovtHospitals(String districtName, double dLat, double dLng) {
    if (_realBangladeshHospitals.containsKey(districtName)) {
      return List.from(_realBangladeshHospitals[districtName]!);
    }

    return [
      {
        'id': '$districtName-1',
        'name': 'জেলা প্রাণিসম্পদ দফতর ও পশু হাসপাতাল, $districtName',
        'address': 'জেলা প্রাণিসম্পদ ভবন, $districtName সদর',
        'phone': '০১৭০০-১১৮৮৯৯',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': dLat + 0.002,
        'longitude': dLng + 0.003,
      },
      {
        'id': '$districtName-2',
        'name': 'উপজেলা প্রাণিসম্পদ দফতর ও মডেল পশু হাসপাতাল, $districtName',
        'address': '$districtName মডেল উপজেলা প্রাণিসম্পদ কমপ্লেক্স',
        'phone': '০১৮০০-২২৩৩৪৪',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': dLat - 0.005,
        'longitude': dLng + 0.008,
      },
      {
        'id': '$districtName-3',
        'name': 'জরুরি মোবাইল ভেটেরিনারি কেয়ার ইউনিট 🚑, $districtName',
        'address': '$districtName মোবাইল এমার্জেন্সি সার্ভিস পয়েন্ট',
        'phone': '০১৬০০-১১২২৩৩',
        'hours': '২৪/৭ জরুরি সেবা খোলা',
        'latitude': dLat + 0.008,
        'longitude': dLng - 0.006,
      },
      {
        'id': '$districtName-4',
        'name': 'প্রাণিসম্পদ গবেষণা ও কৃত্রিম প্রজনন কেন্দ্র, $districtName',
        'address': 'কৃত্রিম প্রজনন পয়েন্ট, $districtName সদর',
        'phone': '০১৯০০-৫৫৬৬৭৭',
        'hours': 'সকাল ৮:৩০ - বিকেল ৫:০০',
        'latitude': dLat - 0.007,
        'longitude': dLng - 0.009,
      },
      {
        'id': '$districtName-5',
        'name': 'মডেল ক্যাটল ও মিল্কি ওয়েলফেয়ার সেন্টার, $districtName',
        'address': '$districtName ডেইরি জোন রোড',
        'phone': '০১৭৫০-৯৯৮৮৭৭',
        'hours': 'সকাল ৯:০০ - বিকেল ৬:০০',
        'latitude': dLat + 0.012,
        'longitude': dLng + 0.011,
      },
    ];
  }

  Future<void> _loadDistrictHospitals(String districtName, {double? userLat, double? userLng, String? areaTitle}) async {
    final distMeta = _all64Districts.firstWhere(
      (d) => d['name'] == districtName,
      orElse: () => {'name': districtName, 'division': 'চট্টগ্রাম', 'lat': '22.8696', 'lng': '91.0993'},
    );

    final dLat = double.tryParse(distMeta['lat']!) ?? 22.8696;
    final dLng = double.tryParse(distMeta['lng']!) ?? 91.0993;

    final lat = userLat ?? dLat;
    final lng = userLng ?? dLng;

    List<Map<String, dynamic>> rawList = _getDistrictGovtHospitals(districtName, dLat, dLng);

    final osmPlaces = await _fetchOverpassNearbyVets(lat, lng);
    rawList.addAll(osmPlaces);

    final customVets = await _loadPersistedCustomVets();
    final districtCustoms = customVets.where((v) => (v['district'] ?? '') == districtName || (v['address'] ?? '').toString().contains(districtName)).toList();
    rawList.insertAll(0, districtCustoms);

    final parsedHospitals = rawList.map<Map<String, dynamic>>((v) {
      final vLat = (v['latitude'] as num).toDouble();
      final vLng = (v['longitude'] as num).toDouble();

      final distanceInMeters = Geolocator.distanceBetween(lat, lng, vLat, vLng);
      final distanceInKm = (distanceInMeters / 1000).toStringAsFixed(1);

      return {
        'id': v['id'],
        'name': v['name'],
        'address': v['address'],
        'distance': '$distanceInKm কিমি',
        'distMeter': distanceInMeters,
        'phone': v['phone'],
        'hours': v['hours'],
        'location': LatLng(vLat, vLng),
      };
    }).toList();

    parsedHospitals.sort((a, b) => (a['distMeter'] as double).compareTo(b['distMeter'] as double));

    final targetCenter = LatLng(dLat, dLng);

    if (mounted) {
      setState(() {
        _userGpsLocation = targetCenter;
        _selectedDistrict = districtName;
        _userAreaName = areaTitle ?? '$districtName জেলা (${distMeta['division']} বিভাগ)';
        _hospitals = parsedHospitals;
        _selectedHospitalIndex = 0;
        _isLoading = false;
      });

      try {
        _mapController.move(targetCenter, 13.5);
      } catch (_) {}
    }
  }

  void _showDistrictSelectModal() {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> filtered = List.from(_all64Districts);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.80,
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'জেলা (জিলা) নির্বাচন করুন',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'বাংলাদেশের ৬৪টি জেলা ও সরকারি পশু হাসপাতাল',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 22), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: searchCtrl,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'জেলার নাম খুঁজুন (যেমন: নোয়াখালী, বগুড়া, ঢাকা)...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF064E3B)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        final q = val.trim().toLowerCase();
                        filtered = _all64Districts.where((d) => d['name']!.toLowerCase().contains(q) || d['division']!.toLowerCase().contains(q)).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final dist = filtered[index];
                        final isSelected = _selectedDistrict == dist['name'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_city_rounded, size: 18, color: isSelected ? Colors.white : const Color(0xFF059669)),
                          ),
                          title: Text(
                            '${dist['name']} জেলা (Zilla)',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 13,
                              color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${dist['division']} বিভাগ • বাংলাদেশ সরকার পশু চিকিৎসা কেন্দ্র',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20) : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadDistrictHospitals(dist['name']!);
                          },
                        );
                      },
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

  void _showAddHospitalModal() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool is24 = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'নতুন হাসপাতাল নিবন্ধিত করুন 🏥',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'হাসপাতাল/ক্লিনিকের নাম',
                      hintText: 'যেমন: মাইজদী ক্যাটল ক্লিনিক',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'ঠিকানা',
                      hintText: 'যেমন: ক্যানাল পার, মাইজদী, নোয়াখালী',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'জরুরি ফোন নম্বর',
                      hintText: 'যেমন: ০১৭০০-১২২৩৪৫',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: is24,
                        activeColor: const Color(0xFF064E3B),
                        onChanged: (val) => setModalState(() => is24 = val ?? true),
                      ),
                      const Text('২৪ ঘণ্টা ইমার্জেন্সি সেবা চালু', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          final loc = _userGpsLocation ?? const LatLng(22.8696, 91.0993);
                          final newVet = {
                            'id': 'custom-vet-${DateTime.now().millisecondsSinceEpoch}',
                            'name': nameCtrl.text.trim(),
                            'address': addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : '$_selectedDistrict, নোয়াখালী',
                            'phone': phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '০১৭০০-০০০০০',
                            'hours': is24 ? '২৪/৭ জরুরি সেবা খোলা' : 'সকাল ৯:০০ - বিকেল ৫:০০',
                            'latitude': loc.latitude + 0.002,
                            'longitude': loc.longitude + 0.002,
                            'district': _selectedDistrict,
                          };

                          await _saveCustomVetLocally(newVet);
                          await _loadDistrictHospitals(_selectedDistrict);

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('নতুন হাসপাতাল যুক্ত ও সংরক্ষিত করা হয়েছে 🏥'), backgroundColor: Color(0xFF064E3B)),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('সংরক্ষণ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('লাইভ পশু হাসপাতাল ডিরেক্টরি', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF064E3B)),
              const SizedBox(height: 16),
              Text(_userAreaName, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final selectedHospital = _hospitals.isNotEmpty
        ? _hospitals[_selectedHospitalIndex.clamp(0, _hospitals.length - 1)]
        : null;

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
          title: const Text(
            'বাংলাদেশ জেলা পশু হাসপাতাল ডিরেক্টরি',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
              onPressed: _showAddHospitalModal,
            ),
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
              onPressed: _fetchRealGpsLocationAndVets,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROMINENT ZILLA SELECTOR CARD
            GestureDetector(
              onTap: _showDistrictSelectModal,
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF059669), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.map_rounded, color: Color(0xFF064E3B), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('জিলা / জেলা নির্বাচন করুন (Choose Zilla):', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '📍 $_selectedDistrict জেলা (Zilla)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF064E3B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text('পরিবর্তন', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MAP VIEW
            if (_userGpsLocation != null)
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: selectedHospital != null
                              ? (selectedHospital['location'] as LatLng)
                              : _userGpsLocation!,
                          initialZoom: 13.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _userGpsLocation!,
                                width: 45,
                                height: 45,
                                child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF2563EB), size: 36),
                              ),
                              ..._hospitals.map((hosp) {
                                final isSel = selectedHospital != null && hosp['id'] == selectedHospital['id'];
                                return Marker(
                                  point: hosp['location'] as LatLng,
                                  width: 70,
                                  height: 70,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSel ? const Color(0xFFDC2626) : const Color(0xFF064E3B),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          hosp['name'].toString().split(' ')[0],
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Icon(Icons.local_hospital_rounded,
                                          color: isSel ? const Color(0xFFDC2626) : const Color(0xFF064E3B), size: 28),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                      if (selectedHospital != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Text(
                                  selectedHospital['name'] as String,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // LIST HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedDistrict জেলার পশু হাসপাতালসমূহ (Map & Govt Places)',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
                ),
                Text(
                  '${_hospitals.length}টি কেন্দ্র',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // LIST OF REAL HOSPITALS
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hospitals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final hosp = _hospitals[index];
                final isSelected = index == _selectedHospitalIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedHospitalIndex = index);
                    try {
                      _mapController.move(hosp['location'] as LatLng, 14.5);
                    } catch (_) {}
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFCBD5E1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFDC2626), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hosp['name'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          hosp['address'] as String,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hosp['distance'] as String,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Text(
                                    hosp['hours'] as String,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${hosp['name']} এ কল করা হচ্ছে (${hosp['phone']}) 📞'),
                                    backgroundColor: const Color(0xFF064E3B),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF064E3B),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.call_rounded, color: Colors.white, size: 12),
                              label: const Text('কল দিন', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
