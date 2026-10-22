// REAL shortcut controller + collection layout. Bookmark persistence, cell artwork,
// context menus and editor boundaries are doubles; this is not a store/Gecko test.
import UIKit

struct BookmarkSnapshot { let guid: String; let url: URL }
enum BookmarkContentSnapshot { case bookmark(BookmarkSnapshot), folder(BookmarkFolderSnapshot) }
struct BookmarkFolderContentsSnapshot { let parent: BookmarkFolderSnapshot; let items: [BookmarkContentSnapshot] }
final class BookmarkStore {
    static let shared = BookmarkStore()
    static var itemCount = 6
    func favoritesFolderContents() -> BookmarkFolderContentsSnapshot {
        BookmarkFolderContentsSnapshot(parent: BookmarkFolderSnapshot(), items: (0..<Self.itemCount).map {
            .bookmark(BookmarkSnapshot(guid: "fixture-\($0)", url: URL(string: "https://example.invalid/\($0)")!))
        })
    }
    func contents(of guid: String) -> BookmarkFolderContentsSnapshot { favoritesFolderContents() }
    func removeBookmark(guid: String) -> Bool { true }
    func removeFolder(guid: String) -> Bool { true }
    func moveBookmarkItem(guid: String, to index: Int, in folder: String) -> Bool { true }
}
extension Notification.Name { static let bookmarkStoreDidChange = Notification.Name("fixture.bookmarks") }
extension HomepageContentMode { var favoriteColumnCount: Int { 4 } }
extension HomepageWallpaper { static func foregroundColor(for mode: HomepageContentMode) -> UIColor { .label } }
enum Haptics { static func prepareRigid() {}; static func rigid() {} }
extension UIApplication { func topViewController() -> UIViewController? { nil } }
final class EditBookmarkViewController: UIViewController {
    init(bookmark: BookmarkSnapshot, store: BookmarkStore) { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
}
class FavoriteSiteCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "fixture-site"
    enum ReorderState { case lifted, resting }
    var contextMenuAnchorView: UIView { self }
    func configure(favorite: BookmarkSnapshot, titleColor: UIColor) { backgroundColor = .systemOrange }
    func setReorderState(_ state: ReorderState, animated: Bool) {}
}
class FavoriteFolderCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "fixture-folder"
    var contextMenuAnchorView: UIView { self }
    func configure(folder: BookmarkFolderSnapshot, previewBookmarks: [BookmarkSnapshot], titleColor: UIColor) {}
    func setReorderState(_ state: FavoriteSiteCollectionViewCell.ReorderState, animated: Bool) {}
}
extension FavoritesSectionViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? { nil }
}

func checkInitialShortcuts() {
    func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap { descendants($0) } }
    for width in [CGFloat(320), 393, 430, 844, 1024] {
        let controller = FavoritesSectionViewController(bookmarkStore: BookmarkStore(), folder: nil, showsSectionTitle: true)
        controller.loadViewIfNeeded()
        let grid = descendants(controller.view).compactMap { $0 as? UICollectionView }.first!
        // Force the problematic first-pass ordering: stack has resolved the
        // section's width, but its nested collection still has zero bounds.
        controller.view.bounds = CGRect(x: 0, y: 0, width: width - 32, height: 400)
        grid.bounds = .zero
        controller.viewDidLayoutSubviews()
        let height = grid.constraints.first { $0.firstAttribute == .height && $0.secondItem == nil }!.constant
        precondition(height >= 230, "Six real shortcuts must get two rows BEFORE a More tap / second parent layout")
        controller.view.layoutIfNeeded()
        grid.layoutIfNeeded()
        precondition(grid.numberOfItems(inSection: 0) == 6)
        precondition(grid.visibleCells.count == 6, "First layout must instantiate shortcut cells")
        precondition(!controller.view.isHidden)
    }
    let empty = FavoritesSectionViewController(bookmarkStore: BookmarkStore(), folder: nil, showsSectionTitle: true)
    BookmarkStore.itemCount = 0
    empty.loadViewIfNeeded()
    precondition(empty.view.isHidden)
    BookmarkStore.itemCount = 6
    NotificationCenter.default.post(name: .bookmarkStoreDidChange, object: nil)
    empty.view.frame = CGRect(x: 0, y: 0, width: 361, height: 400)
    empty.view.layoutIfNeeded()
    precondition(!empty.view.isHidden, "Real bookmark notification must reveal shortcuts without More")
}
