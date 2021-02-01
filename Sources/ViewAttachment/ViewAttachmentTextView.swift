import UIKit

protocol ViewAttachmentTextViewDelegate: AnyObject {
    func attachmentTextView(_ attachmentTextView: ViewAttachmentTextView, shouldDeleteAttachments attachments: [ViewAttachment]) -> Bool
    func attachmentTextView(_ attachmentTextView: ViewAttachmentTextView, willDeleteAttachment attachment: ViewAttachment)
    func attachmentTextView(_ attachmentTextView: ViewAttachmentTextView, didDeleteAttachment attachment: ViewAttachment)
}

final class ViewAttachmentTextView: UIView, UITextViewDelegate {
    static let RTAttachmentPlaceholderString = "\u{fffc}"
    var textView: UITextView?
    var selectedRang: NSRange {
        get {
            textView?.selectedRange ?? .init()
        }
        set {
            textView?.selectedRange = newValue
        }
    }
    var length: Int {
        textStorage.length
    }
    var paragraphStyle: NSParagraphStyle = .default
    var font: UIFont = .systemFont(ofSize: 17.0)
    var textContainerInset: UIEdgeInsets {
        get {
            textView?.textContainerInset ?? .init()
        }
        set {
            textView?.textContainerInset = newValue
        }
    }
    var manager: ViewAttachmentLayoutManagerInternal
    weak var delegate: ViewAttachmentTextViewDelegate?

    private var textStorage: NSTextStorage

    override init(frame: CGRect) {
        self.textStorage = NSTextStorage(string: "",
                                         attributes: [
                                            .font: self.font,
                                            .paragraphStyle: self.paragraphStyle
                                         ])
        self.manager = ViewAttachmentLayoutManagerInternal()
        self.textStorage.addLayoutManager(self.manager)

        super.init(frame: frame)
        let container = NSTextContainer()
        container.widthTracksTextView = true

        manager.addTextContainer(container)

        self.textView = TextViewInternal(frame: .zero,
                                         textContainer: container)
        textView?.translatesAutoresizingMaskIntoConstraints = false
        self.textView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.textView?.delegate = self
        self.textView?.font = self.font
        self.addSubview(self.textView!)
        NSLayoutConstraint.activate([
            textView!.topAnchor.constraint(equalTo: topAnchor),
            textView!.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView!.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView!.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func insert(viewAttachment: ViewAttachment) {
        viewAttachment.attachedView.isHidden = true
        viewAttachment.attachedView.translatesAutoresizingMaskIntoConstraints = true
        textView?.addSubview(viewAttachment.attachedView)
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: self.selectedRang,
                                    with: Self.RTAttachmentPlaceholderString)
        textStorage.addAttributes([
            .attachment: viewAttachment,
            .font: font,
            .paragraphStyle: paragraphStyle],
                                   range: textStorage.editedRange)
        let range = NSRange(location: min(textStorage.editedRange.location + textStorage.editedRange.length, textStorage.length),
                            length: 0)
        self.textStorage.endEditing()
        self.selectedRang = range
    }

    func insert(viewAttachment: ViewAttachment, at index: Int) {
        viewAttachment.attachedView.isHidden = true
        viewAttachment.attachedView.translatesAutoresizingMaskIntoConstraints = true
        textView?.addSubview(viewAttachment.attachedView)
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange(location: index, length: 0),
                                    with: Self.RTAttachmentPlaceholderString)
        textStorage.addAttributes([
            .attachment: viewAttachment,
            .font: font,
            .paragraphStyle: paragraphStyle],
                                   range: textStorage.editedRange)
        let range = NSRange(location: min(textStorage.editedRange.location + textStorage.editedRange.length, textStorage.length),
                            length: 0)
        self.textStorage.endEditing()
        self.selectedRang = range
    }

    func remove(viewAttachment: ViewAttachment) {
        self.textStorage.enumerateAttribute(.attachment,
                                            in: NSRange(location: 0, length: textStorage.length),
                                            options: .longestEffectiveRangeNotRequired) { (value, range, stop) in
            if let attach = value as? ViewAttachment, attach == viewAttachment {
                textStorage.removeAttribute(.attachment, range: range)
                textStorage.replaceCharacters(in: range, with: "")
                viewAttachment.attachedView.removeFromSuperview()
                stop.pointee = true
            }
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var shouldChange = true
        var arr: [ViewAttachment] = []

        self.textStorage.enumerateAttribute(.attachment,
                                            in: range,
                                            options: .longestEffectiveRangeNotRequired) { (value, range, stop) in
            if let attachment = value as? ViewAttachment {
                arr.append(attachment)
            }
        }

        if !arr.isEmpty {
            shouldChange = self.delegate?
                .attachmentTextView(self,
                                    shouldDeleteAttachments: arr) ?? false
        }

        if shouldChange {
            arr.removeAll()
            textStorage.enumerateAttribute(.attachment,
                                           in: range,
                                           options: .longestEffectiveRangeNotRequired) { (value, range, stop) in
                if let attachment = value as? ViewAttachment {
                    self.delegate?.attachmentTextView(self, willDeleteAttachment: attachment)
                    self.textStorage.removeAttribute(.attachment,
                                                     range: range)
                    attachment.attachedView.removeFromSuperview()
                    self.delegate?.attachmentTextView(self,
                                                      didDeleteAttachment: attachment)
                }

            }
        }

        return shouldChange
    }
}

