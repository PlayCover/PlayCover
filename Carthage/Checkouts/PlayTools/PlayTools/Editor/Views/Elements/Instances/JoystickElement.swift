//
//  Joystick.swift
//  PlayTools
//
//  Created by 许沂聪 on 2024/6/2.
//

import Foundation

class JoystickElement: Element {
    var changeModeButton: UIView?
    var joystickModeLabel: UILabel?

    func setKey(showChild: Bool, name: String) {
        guard let childButtons = (model as? JoystickModel)?.joystickButtons.map({ controller in
            controller.button }) else { return }
        setTitle(name, for: UIControl.State.normal)
        childButtons.forEach({ view in view.isHidden = !showChild})
    }

    func setJoystickMode(mode: JoystickMode) {
        var displayName: String
        if mode == .FIXED {
            displayName = NSLocalizedString("keymappingEditor.joystickMode.fixed",
                                            tableName: "Playtools", value: "Fixed Joystick", comment: "")
        } else if mode == .FLOATING {
            displayName = NSLocalizedString("keymappingEditor.joystickMode.floating",
                                            tableName: "Playtools", value: "Floating Joystick", comment: "")
        } else {
            displayName = "Unknown"
        }
        self.joystickModeLabel?.text = displayName
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        createChangeModeButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.clipsToBounds = false
        createChangeModeButton()
    }

    override func update() {
        super.update()
        layer.cornerRadius = 0.3 * bounds.size.width
        let buttonSize = frame.width / 3
        let xCoord1 = (frame.width / 2) - buttonSize / 2
        let yCoord1 = buttonSize / 4.5
        let xCoord2 = (frame.width / 2) - buttonSize / 2
        let yCoord2 = frame.width - buttonSize - buttonSize / 4.5
        guard let childButtons = (model as? JoystickModel)?.joystickButtons.map({ controller in
            controller.button }) else { return }
        let upButton = childButtons[0]
        let downButton = childButtons[1]
        let leftButton = childButtons[2]
        let rightButton = childButtons[3]
        upButton.frame = CGRect(x: xCoord1, y: yCoord1, width: buttonSize, height: buttonSize)
        downButton.frame = CGRect(x: xCoord2, y: yCoord2, width: buttonSize, height: buttonSize)
        leftButton.frame = CGRect(x: yCoord1, y: xCoord1, width: buttonSize, height: buttonSize)
        rightButton.frame = CGRect(x: yCoord2, y: xCoord2, width: buttonSize, height: buttonSize)
        childButtons.forEach({ view in view.layer.cornerRadius = 0.5 * view.bounds.size.width})

        if let changeModeButton = self.changeModeButton {
            let buttonWidth = frame.width
            let buttonHeight = CGFloat(2.75).absoluteSize
            let spaceHeight = CGFloat(10)
            let buttonX = CGFloat(0)
            let buttonY = CGFloat(0) - spaceHeight - buttonHeight
            changeModeButton.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        }
    }

    override func focus(_ focus: Bool) {
        super.focus(focus)
        self.changeModeButton?.isHidden = !focus
    }

    // Since the change mode button is outside its parent's bounds,
    // we need to override this method to ensure it receives click events
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let outsideView = self.changeModeButton, !outsideView.isHidden && outsideView.frame.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }

    func createChangeModeButton() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: CGFloat(1.25).absoluteSize)
        label.textColor = UIColor.white
        label.textAlignment = .center

        let icon = UIImageView(image: UIImage(systemName: "arrow.2.circlepath"))
        icon.tintColor = UIColor.white
        icon.widthAnchor.constraint(equalToConstant: CGFloat(1.5).absoluteSize).isActive = true
        icon.heightAnchor.constraint(equalToConstant: CGFloat(1.5).absoluteSize).isActive = true

        let spacer1 = UIView()
        spacer1.widthAnchor.constraint(equalToConstant: CGFloat(1.25).absoluteSize).isActive = true
        let spacer2 = UIView()
        spacer2.widthAnchor.constraint(equalToConstant: CGFloat(0.5).absoluteSize).isActive = true
        let spacer3 = UIView()
        spacer3.widthAnchor.constraint(equalToConstant: CGFloat(1.25).absoluteSize).isActive = true

        let hStackView = UIStackView(arrangedSubviews: [spacer1, label, spacer2, icon, spacer3])
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        hStackView.layer.cornerRadius = 10
        hStackView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changeModeButtonTapped(_:)))
        hStackView.addGestureRecognizer(gesture)

        let vStackView = UIStackView(arrangedSubviews: [hStackView])
        vStackView.axis = .vertical
        vStackView.alignment = .center

        self.addSubview(vStackView)
        self.changeModeButton = vStackView
        self.joystickModeLabel = label
    }

    @objc func changeModeButtonTapped(_ sender: UITapGestureRecognizer) {
        (model as? JoystickModel)?.switchToNextJoystickMode()
    }
}
