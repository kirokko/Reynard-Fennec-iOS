// ieynec homepage cards use live browser state, never fabricated history or totals.
// GPL-3.0.
import UIKit

final class FennecHomepageSummaryView: UIStackView {
    var onResume: ((UUID) -> Void)?
    var onProtection: (() -> Void)?
    private var resumedTabID: UUID?
    private let protection = FennecClosureButton(frame: .zero)
    private let continueStack = UIStackView()
    private let resume = FennecClosureButton(frame: .zero)
    private let preview = UIImageView()
    private let titleLabel = UILabel()
    private let urlLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        spacing = 36
        let protectionRow = UIStackView(arrangedSubviews: [UIView(), protection, UIView()])
        protectionRow.axis = .horizontal
        protectionRow.arrangedSubviews[0].widthAnchor.constraint(equalTo: protectionRow.arrangedSubviews[2].widthAnchor).isActive = true
        protection.backgroundColor = FennecTheme.card
        protection.layer.cornerRadius = 20
        protection.setTitleColor(FennecTheme.ink, for: .normal)
        protection.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        protection.titleLabel?.adjustsFontForContentSizeCategory = true
        protection.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        protection.setTitle("  " + FennecTheme.text("Tracking protection"), for: .normal)
        protection.setImage(UIImage(systemName: "checkmark.shield"), for: .normal)
        protection.tintColor = FennecTheme.selectedOutline
        protection.onTap = { [weak self] in self?.onProtection?() }
        addArrangedSubview(protectionRow)

        continueStack.axis = .vertical
        continueStack.spacing = 16
        let heading = UILabel()
        heading.text = FennecTheme.text("Continue")
        heading.font = .preferredFont(forTextStyle: .body)
        heading.adjustsFontForContentSizeCategory = true
        heading.textColor = FennecTheme.ink
        continueStack.addArrangedSubview(heading)
        continueStack.addArrangedSubview(resume)
        // Attach this subtree only when there is a tab. Hiding an arranged
        // stack would impose 0pt height against the card's required minimum.
        resume.accessibilityIdentifier = "homepage.resume"
        resume.backgroundColor = FennecTheme.card
        resume.layer.cornerRadius = 8
        resume.clipsToBounds = true
        resume.onTap = { [weak self] in
            guard let self, let id = self.resumedTabID else { return }
            self.onResume?(id)
        }
        preview.contentMode = .scaleAspectFill
        preview.clipsToBounds = true
        // Full-page thumbnails have huge intrinsic dimensions. They must fill
        // the card, never determine the card height or homepage width.
        preview.setContentCompressionResistancePriority(UILayoutPriority(1), for: .vertical)
        preview.setContentCompressionResistancePriority(UILayoutPriority(1), for: .horizontal)
        preview.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        titleLabel.numberOfLines = 2
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = FennecTheme.ink
        urlLabel.font = .preferredFont(forTextStyle: .caption1)
        urlLabel.textColor = .secondaryLabel
        urlLabel.lineBreakMode = .byTruncatingMiddle
        for label in [titleLabel, urlLabel] {
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        let labels = UIStackView(arrangedSubviews: [titleLabel, urlLabel])
        labels.axis = .vertical
        labels.spacing = 6
        for child in [preview, labels] {
            child.translatesAutoresizingMaskIntoConstraints = false
            child.isUserInteractionEnabled = false
            child.isAccessibilityElement = false
            resume.addSubview(child)
        }
        let preferredHeight = resume.heightAnchor.constraint(equalToConstant: 88)
        preferredHeight.priority = .defaultLow // Larger accessibility text can grow.
        NSLayoutConstraint.activate([
            preferredHeight,
            preview.leadingAnchor.constraint(equalTo: resume.leadingAnchor),
            preview.topAnchor.constraint(equalTo: resume.topAnchor),
            preview.bottomAnchor.constraint(equalTo: resume.bottomAnchor),
            preview.widthAnchor.constraint(equalToConstant: 96),
            labels.leadingAnchor.constraint(equalTo: preview.trailingAnchor, constant: 16),
            labels.trailingAnchor.constraint(equalTo: resume.trailingAnchor, constant: -12),
            labels.centerYAnchor.constraint(equalTo: resume.centerYAnchor),
            labels.topAnchor.constraint(greaterThanOrEqualTo: resume.topAnchor, constant: 12),
            labels.bottomAnchor.constraint(lessThanOrEqualTo: resume.bottomAnchor, constant: -12),
            resume.heightAnchor.constraint(greaterThanOrEqualToConstant: 88),
        ])
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refresh(tabs: [Tab], blockedCount: Int) {
        // This number is deliberately scoped to currently open regular tabs.
        let countDescription = String(format: FennecTheme.text("%d blocked trackers in open tabs"), blockedCount)
        if protection.accessibilityValue != countDescription { protection.accessibilityValue = countDescription }
        let tab = tabs.filter {
            !$0.isPrivate && !($0.url ?? "").isEmpty && !($0.url ?? "").hasPrefix("about:")
        }.max { $0.state.selectionOrder < $1.state.selectionOrder }
        resumedTabID = tab?.id
        guard let tab else {
            if continueStack.superview != nil {
                removeArrangedSubview(continueStack)
                continueStack.removeFromSuperview()
            }
            return
        }
        if continueStack.superview == nil { addArrangedSubview(continueStack) }
        let title = tab.title.isEmpty ? (tab.url ?? "") : tab.title
        if titleLabel.text != title { titleLabel.text = title }
        if urlLabel.text != tab.url { urlLabel.text = tab.url }
        let image = tab.thumbnail ?? tab.favicon
        if preview.image !== image { preview.image = image }
        let description = [FennecTheme.text("Continue"), titleLabel.text, urlLabel.text].compactMap { $0 }.joined(separator: ", ")
        if resume.accessibilityLabel != description { resume.accessibilityLabel = description }
    }
}
