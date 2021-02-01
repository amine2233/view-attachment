import UIKit

final class ViewAttachment: NSTextAttachment {
    var attachedView: UIView {
        didSet {
            updateBounds()
        }
    }
    var placeholderText: String?
    var isFullWidth: Bool
    var userInfo: [String: Any] = [:]

    var attributedString: NSAttributedString {
        NSAttributedString(attachment: self)
    }

    init(attachedView: UIView, placeholderText: String? = nil, isFullWidth: Bool = false) {
        self.attachedView = attachedView
        self.placeholderText = placeholderText
        self.isFullWidth = isFullWidth
        let data = placeholderText != nil ? placeholderText!.data(using: .utf8) : nil
        super.init(data: data, ofType: "application/x-view")
        updateBounds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func attributedString(withAttributes attributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        let attrString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: self))
        attrString.addAttributes(attributes, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }

    private func updateBounds() {
//        var newFrame = attachedView.frame
//        newFrame.size = CGSize(width: attachedView.frame.width, height: UIView.layoutFittingExpandedSize.height)
//        attachedView.frame = newFrame
//
//        // Make sure the contents of the cell have the correct layout.
//        attachedView.setNeedsLayout()
//        attachedView.layoutIfNeeded()

        // Get the size of the cell
        let computedSize = attachedView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // Apple: "Only consider the height for cells, because the contentView isn't anchored correctly sometimes." We use ceil to make sure we get rounded numbers and no half pixels.
        attachedView.frame.size = computedSize
        self.bounds = attachedView.bounds
    }

    override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return nil
    }

    override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int) -> CGRect {
        var rect = super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        if isFullWidth {
            rect.size.width = lineFrag.width - (textContainer?.lineFragmentPadding ?? 0 * 2)
        }
        return rect
    }
}
