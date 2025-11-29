class AdManager {
  static const bool useRealAds = false; // mettre true quand tu actives AdMob

  static String? get bannerUnitId {
    if (!useRealAds) {
      return "ca-app-pub-3940256099942544/6300978111"; // bannière test
    }
  return "TON_ID_ADMOB_ICI";     // quand tu activeras les vraies pubs
  }
}
