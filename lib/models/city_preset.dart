/// ערים נפוצות בישראל - לצורך חישוב זמני זריחה/שקיעה (זמני הלכה) ב-kosher_dart.
///
/// כל עיר מוגדרת ע"י קואורדינטות ואזור זמן. ירושלים היא ברירת המחדל.
enum CityPreset {
  jerusalem('jerusalem', 'ירושלים', 31.7683, 35.2137, 754.0),
  telAviv('tel_aviv', 'תל אביב', 32.0853, 34.7818, 5.0),
  bneiBrak('bnei_brak', 'בני ברק', 32.0809, 34.8338, 40.0),
  haifa('haifa', 'חיפה', 32.7940, 34.9896, 250.0),
  beerSheva('beer_sheva', 'באר שבע', 31.2518, 34.7913, 260.0),
  netanya('netanya', 'נתניה', 32.3329, 34.8599, 30.0),
  ashdod('ashdod', 'אשדוד', 31.8044, 34.6553, 20.0),
  rishonLezion('rishon', 'ראשון לציון', 31.9729, 34.7925, 40.0),
  petachTikva('petach_tikva', 'פתח תקווה', 32.0868, 34.8856, 50.0),
  holon('holon', 'חולון', 32.0114, 34.7722, 35.0),
  ramatGan('ramat_gan', 'רמת גן', 32.0680, 34.8248, 45.0),
  batYam('bat_yam', 'בת ים', 32.0167, 34.7500, 10.0),
  safed('safed', 'צפת', 32.9646, 35.4960, 900.0),
  tiberias('tiberias', 'טבריה', 32.7922, 35.5312, -200.0),
  hebron('hebron', 'חברון', 31.5326, 35.0998, 930.0),
  eilat('eilat', 'אילת', 29.5581, 34.9482, 15.0),
  ashkelon('ashkelon', 'אשקלון', 31.6688, 34.5743, 60.0),
  rehovot('rehovot', 'רחובות', 31.8969, 34.8085, 75.0),
  ;

  final String id;
  final String displayName;
  final double latitude;
  final double longitude;

  /// גובה מעל פני הים במטרים - משפיע על זמני הזריחה/שקיעה המדויקים
  final double elevationMeters;

  /// אזור זמן - כל ערי ישראל הן Asia/Jerusalem
  String get timezone => 'Asia/Jerusalem';

  const CityPreset(
    this.id,
    this.displayName,
    this.latitude,
    this.longitude,
    this.elevationMeters,
  );

  static CityPreset? fromId(String? id) {
    if (id == null) return null;
    for (final c in CityPreset.values) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// רשימה ממוינת לפי שם בעברית - שימושי לתפריט
  static List<CityPreset> sortedByName() {
    final list = List<CityPreset>.from(CityPreset.values);
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }
}
