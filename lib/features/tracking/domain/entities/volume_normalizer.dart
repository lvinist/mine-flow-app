/// Normalizes bank (BCM) and loose (LCM) cubic meters into a single
/// bank-equivalent volume using a per-material swell factor.
///
/// Earthworks measure the same material in two states: *bank* (in-situ, BCM)
/// and *loose* (excavated, LCM). They relate by the swell factor:
///
///     loose = bank × (1 + swell)   ⇒   bank = loose / (1 + swell)
///
/// The reported "net" volume is therefore `BCM + LCM / (1 + swell)` — every
/// cubic meter expressed on the bank (in-situ) basis, so BCM and LCM are never
/// summed raw (which would double-count the swell).
library;

class VolumeNormalizer {
  /// Default swell factor (25%) used when a material has no specific entry.
  ///
  /// Configurable per material via [materialSwellFactors].
  static const double defaultSwellFactor = 0.25;

  /// Per-material swell factors keyed by material type string.
  ///
  /// Materials absent here fall back to [defaultSwellFactor]. Add calibrated
  /// entries as the survey team measures them, e.g.
  /// `{'OB / Waste': 0.30, 'Soil': 0.20}`.
  static const Map<String, double> materialSwellFactors = <String, double>{};

  /// The swell factor for [materialType], defaulting to [defaultSwellFactor].
  static double swellFactorFor(String? materialType) =>
      materialSwellFactors[materialType] ?? defaultSwellFactor;

  /// Bank-equivalent volume from [bcm] and [lcm] for [materialType].
  static double bankEquivalent({
    required double bcm,
    required double lcm,
    String? materialType,
  }) {
    return bcm + lcm / (1.0 + swellFactorFor(materialType));
  }
}
