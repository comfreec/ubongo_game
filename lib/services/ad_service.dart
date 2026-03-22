// 광고 기능 임시 비활성화 - AdMob ID 발급 후 재활성화 예정
class AdService {
  AdService._();
  static final AdService instance = AdService._();
  Future<void> initialize() async {}
  void showAd({required void Function() onComplete}) => onComplete();
}
