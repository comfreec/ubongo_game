// 웹용 - AdMob 미지원, 광고 없이 바로 onComplete 호출
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  Future<void> initialize() async {}

  void showAd({required void Function() onComplete}) => onComplete();
}
