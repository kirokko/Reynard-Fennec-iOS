// Real download categories matching Fennec's All / Images / Other controls.
// Foundation-only classification is testable without downloads or engine state.
// GPL-3.0.
import Foundation

enum FennecDownloadFilter: CaseIterable {
    case all, images, other

    var title: String {
        switch self {
        case .all: return "All"
        case .images: return "Images"
        case .other: return "Other"
        }
    }

    func matches(fileName: String, mimeType: String?) -> Bool {
        if self == .all { return true }
        let mime = mimeType?.split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() } ?? ""
        let image: Bool
        if mime.hasPrefix("image/") {
            image = true
        } else if !mime.isEmpty && mime != "application/octet-stream" {
            image = false
        } else {
            let ext = (fileName as NSString).pathExtension.lowercased()
            image = Self.imageExtensions.contains(ext)
        }
        return self == .images ? image : !image
    }

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "webp", "avif", "heic", "heif",
        "svg", "bmp", "tif", "tiff", "ico", "jxl", "dng",
    ]
}
