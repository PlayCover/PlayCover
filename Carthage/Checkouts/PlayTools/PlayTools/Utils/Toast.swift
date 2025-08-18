//
//  Toast.swift
//  PlayTools
//

import Foundation
import UIKit

class Toast {
    public static func showOver(msg: String) {
        if let parent = screen.keyWindow {
            Toast.show(message: msg, parent: parent)
        }
    }
    static var hintView: [UIView] = []

    private static let gap: CGFloat = 40

    public static func hideHint(hint: UIView) {
        guard let id = hintView.firstIndex(of: hint) else {return}
        for index in 0..<hintView.count {
            if index < id {
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                    hintView[index].layer.position.y -= hint.frame.size.height + gap
                })
            } else if index > id {
                hintView[index-1] = hintView[index]
            }
        }
        hintView.removeLast()
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            hint.alpha = 0.0
        }, completion: {_ in
            hint.removeFromSuperview()
        })
    }

    private static func getAttributedString(title: String, text: [String]) -> NSMutableAttributedString {
        var heading = title
        if !text.isEmpty {
            heading += "\n"
        }
        let txt = NSMutableAttributedString(string: text.reduce(into: heading, { result, string in
            result += string
        }))
        var messageLength = 0
        var highlight = false
        for msg in text {
            txt.addAttribute(.foregroundColor, value: highlight ? UIColor.cyan: UIColor.white,
                             range: NSRange(location: heading.count + messageLength, length: msg.count))
            highlight = !highlight
            messageLength += msg.count
        }
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        txt.addAttribute(.paragraphStyle, value: style,
                         range: NSRange(location: 0, length: heading.count + messageLength))
        txt.addAttribute(.font, value: UIFont.systemFont(ofSize: 28, weight: .bold),
                         range: NSRange(location: 0, length: heading.count))
        txt.addAttribute(.foregroundColor, value: UIColor.white,
                         range: NSRange(location: 0, length: heading.count))
        txt.addAttribute(.font, value: UIFont.systemFont(ofSize: 28),
                         range: NSRange(location: heading.count, length: messageLength))
        return txt
    }

    public static func showHint(title: String, text: [String] = [], timeout: Double = -3,
                                notification: NSNotification.Name? = nil) {
        let parent = screen.keyWindow!

        // Width and height here serve as an upper limit.
        // Text would fill width first, then wrap, then fill height, then scroll
        let messageLabel = UITextView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
        messageLabel.attributedText = getAttributedString(title: title, text: text)
        messageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        messageLabel.alpha = 1.0
        messageLabel.clipsToBounds = true
        messageLabel.isUserInteractionEnabled = false
        messageLabel.frame.size = messageLabel.sizeThatFits(messageLabel.frame.size)
        messageLabel.layer.cornerCurve = CALayerCornerCurve.continuous
        messageLabel.layer.cornerRadius = messageLabel.frame.size.height / 4
        messageLabel.frame.size.width += messageLabel.layer.cornerRadius * 2
        messageLabel.center.x = parent.center.x
        messageLabel.center.y = -messageLabel.frame.size.height / 2

        // Disable editing
        messageLabel.isEditable = false
        messageLabel.isSelectable = false

        hintView.append(messageLabel)
        parent.addSubview(messageLabel)

        if hintView.count > 4 {
            hideHint(hint: hintView.first!)
        }
        var life = timeout
        if let note = notification {
            let center = NotificationCenter.default
            var token: NSObjectProtocol?
            token = center.addObserver(forName: note, object: nil, queue: OperationQueue.main) { _ in
                center.removeObserver(token!)
                hideHint(hint: messageLabel)
            }
        } else if life < 0 {
            life = 3
        }
        if life >= 0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5 + life, qos: .background) {
                hideHint(hint: messageLabel)
            }
        }
        for view in hintView {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                view.layer.position.y += messageLabel.frame.size.height + gap
            })
        }
    }

    static func syncUserDefaults() -> Float {
        let persistenceKeyname = "playtoolsKeymappingDisabledAt"
        let lastUse = UserDefaults.standard.float(forKey: persistenceKeyname)
        var thisUse = lastUse
        if lastUse < 1 {
            thisUse = 2
        } else {
            thisUse = Float(Date.timeIntervalSinceReferenceDate)
        }
        var token2: NSObjectProtocol?
        let center = NotificationCenter.default
        token2 = center.addObserver(forName: NSNotification.Name.playtoolsCursorWillShow,
                                    object: nil, queue: OperationQueue.main) { _ in
            center.removeObserver(token2!)
            UserDefaults.standard.set(thisUse, forKey: persistenceKeyname)
        }
        return lastUse
    }

    public static func initialize() {
        let lastUse = syncUserDefaults()
        if lastUse > Float(Date.now.addingTimeInterval(-86400*14).timeIntervalSinceReferenceDate) {
            return
        }
        Toast.showHint(title: NSLocalizedString("hint.mouseMapping.title",
                                                tableName: "Playtools",
                                                value: "Mouse mapping disabled", comment: ""),
                       text: [NSLocalizedString("hint.mouseMapping.content.before",
                                                tableName: "Playtools",
                                                value: "Press", comment: ""),
                              " option ⌥ ",
                              NSLocalizedString("hint.mouseMapping.content.after",
                                                tableName: "Playtools",
                                                value: "to enable mouse mapping", comment: "")],
                       timeout: 10,
                       notification: NSNotification.Name.playtoolsCursorWillHide)
        let center = NotificationCenter.default
        var token: NSObjectProtocol?
        token = center.addObserver(forName: NSNotification.Name.playtoolsCursorWillHide,
                                   object: nil, queue: OperationQueue.main) { _ in
            center.removeObserver(token!)
            Toast.showHint(title: NSLocalizedString("hint.showCursor.title",
                                                    tableName: "Playtools",
                                                    value: "Cursor locked", comment: ""),
                           text: [NSLocalizedString("hint.showCursor.content.before",
                                                    tableName: "Playtools",
                                                    value: "Press", comment: ""),
                                  " option ⌥ ",
                                  NSLocalizedString("hint.showCursor.content.after",
                                                    tableName: "Playtools",
                                                    value: "to unlock cursor", comment: "")],
                           timeout: 10,
                           notification: NSNotification.Name.playtoolsCursorWillShow)
        }
    }

    // swiftlint:disable:next function_body_length
    private static func show(message: String, parent: UIView) {
        let toastContainer = UIView(frame: CGRect())
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 25
        toastContainer.clipsToBounds  =  true
        toastContainer.isUserInteractionEnabled = false

        let toastLabel = UILabel(frame: CGRect())
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font.withSize(12.0)
        toastLabel.text = message
        toastLabel.clipsToBounds  =  true
        toastLabel.numberOfLines = 0

        toastContainer.addSubview(toastLabel)
        parent.addSubview(toastContainer)

        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        let toastConstraint1 = NSLayoutConstraint(item: toastLabel,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: toastContainer,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 15)
        let toastConstraint2 = NSLayoutConstraint(item: toastLabel,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: toastContainer,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: -15)
        let toastConstraint3 = NSLayoutConstraint(item: toastLabel,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: toastContainer,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: -15)
        let toastConstraint4 = NSLayoutConstraint(item: toastLabel,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: toastContainer,
                                                  attribute: .top,
                                                  multiplier: 1,
                                                  constant: 15)
        toastContainer.addConstraints([toastConstraint1, toastConstraint2, toastConstraint3, toastConstraint4])

        let controllerConstraint1 = NSLayoutConstraint(item: toastContainer,
                                                       attribute: .leading,
                                                       relatedBy: .equal,
                                                       toItem: parent,
                                                       attribute: .leading,
                                                       multiplier: 1,
                                                       constant: 65)
        let controllerConstraint2 = NSLayoutConstraint(item: toastContainer,
                                                       attribute: .trailing,
                                                       relatedBy: .equal,
                                                       toItem: parent,
                                                       attribute: .trailing,
                                                       multiplier: 1,
                                                       constant: -65)
        let controllerConstraint3 = NSLayoutConstraint(item: toastContainer,
                                                       attribute: .bottom,
                                                       relatedBy: .equal,
                                                       toItem: parent,
                                                       attribute: .bottom,
                                                       multiplier: 1,
                                                       constant: -75)
        parent.addConstraints([controllerConstraint1, controllerConstraint2, controllerConstraint3])

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: {_ in
                toastContainer.removeFromSuperview()
            })
        })
    }
}
