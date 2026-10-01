//
//  SpicyBrand.swift
//  MR. SPICY UI — brand asset access
//
//  MR. SPICY UI v1.0.0
//
//  The MR. SPICY mark is decoded once and cached. Components must obtain the
//  logo through this type rather than calling `UIImage(named:)` directly, so
//  that repeated overlay presentations never re-decode the asset.
//

#if canImport(UIKit)
import UIKit

public enum SpicyBrand {

    public static let uiLayerVersion = "1.0.0"

    /// Name of the image set in `Assets.xcassets`.
    public static let logoAssetName = "MrSpicyLogo"

    private static let cache = NSCache<NSString, UIImage>()

    /// Returns the MR. SPICY mark, decoded once per process.
    ///
    /// Aspect ratio is never altered by this accessor; callers must use
    /// `.scaleAspectFit`.
    public static func logo() -> UIImage? {
        let key = logoAssetName as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = UIImage(named: logoAssetName,
                                  in: SpicyL10n.resourceBundle,
                                  compatibleWith: nil) else {
            // Missing asset is a packaging error, not a runtime fallback case.
            #if DEBUG
            assertionFailure("MR. SPICY: '\(logoAssetName)' is missing from the resource bundle")
            #endif
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }

    /// Clears cached brand imagery (call on memory-pressure notifications).
    public static func purgeCaches() {
        cache.removeAllObjects()
    }
}
#endif
