import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsInitializer {
  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }
}
