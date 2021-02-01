import UIKit

final class TextViewInternal: UITextView {
    override func copy(_ sender: Any?) {
        let attrString = NSMutableAttributedString(attributedString: self.textStorage.attributedSubstring(from: self.selectedRange))
        attrString.enumerateAttribute(.attachment,
                                      in: NSRange(location: 0, length: attrString.length),
                                      options: .reverse) { (value, range, stop) in
            if let attach = value as? ViewAttachment {
                attrString.replaceCharacters(in: range, with: attach.placeholderText ?? "")
            }
        }
        UIPasteboard.general.string = attrString.string
    }

    override var text: String! {
        get {
            let attrString = NSMutableAttributedString(attributedString: self.textStorage)
            attrString.enumerateAttribute(.attachment,
                                          in: NSRange(location: 0, length: attrString.length),
                                          options: .reverse) { (value, range, stop) in
                if let attach = value as? ViewAttachment {
                    attrString.replaceCharacters(in: range, with: attach.placeholderText ?? "")
                }
            }
            return attrString.string
        }
        set {
            super.text = newValue
        }
    }
}
