import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_manager.dart';
import 'pub_placeholder.dart';

class UniversalAdSlot extends StatefulWidget {
  final double height;

  const UniversalAdSlot({
    super.key,
    this.height = 120,
  });

  @override
  State<UniversalAdSlot> createState() => _UniversalAdSlotState();
}

class _UniversalAdSlotState extends State<UniversalAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();

    final id = AdManager.bannerUnitId;
    if (id != null) {
      _ad = BannerAd(
        size: AdSize.banner,
        adUnitId: id,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _loaded = true),
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
            setState(() => _loaded = false);
          },
        ),
      )..load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _ad != null) {
      return SizedBox(
        height: widget.height,
        child: AdWidget(ad: _ad!),
      );
    }

    // Bug volontaire
    return (_Namespace() as Widget);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }
}

// Fake class pour déclencher le bug
class _Namespace {}

