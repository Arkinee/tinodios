//
//  CircularProgressView.swift
//  Tinodios
//

//  Copyright © 2019 Tinode. All rights reserved.
//

import Foundation
import UIKit

// Circular progress indicator (like UIProgressBar).
class CircularProgressView: UIView {
    // Track line width
    static private let kTrackLineWidth: CGFloat = 1
    // Progress line width
    static private let kProgressLineWidth: CGFloat = 3
    // Size of the stop button compare to the size of the control.
    static private let kButtonSize: CGFloat = 0.5

    var stopButton: UIButton = {
        let button = UIButton()
        button.setTitle("✕", for: .normal)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        // button.backgroundColor = .blue
        return button
    }()

    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()

    private var progress: Float = 0

    private var progressColor = UIColor.systemBlue {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
            stopButton.setTitleColor(progressColor, for: .normal)
        }
    }

    private var trackColor = UIColor.systemGray {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(stopButton)
        bringSubviewToFront(stopButton)
        layoutComponents()
    }

    convenience public init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override var frame: CGRect {
        didSet {
            layoutComponents()
        }
    }

    private func layoutComponents() {
        let size = self.frame.size

        self.layer.cornerRadius = size.width / 2
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: size.width / 2, y: size.height / 2),
            radius: (size.width - 1.5) / 2,
            startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)

        // Progress track.
        trackLayer.path = circlePath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = CircularProgressView.kTrackLineWidth
        trackLayer.strokeEnd = 1.0
        layer.addSublayer(trackLayer)

        // Actual progress indicator.
        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = CircularProgressView.kProgressLineWidth
        progressLayer.strokeEnd = CGFloat(self.progress)
        progressLayer.lineCap = .round
        layer.addSublayer(progressLayer)

        // Place stopButton at the center of the view.
        let btnSize = CGSize(width: size.width * CircularProgressView.kButtonSize, height: size.height * CircularProgressView.kButtonSize)
        let btnOrigin = CGPoint(x: (size.width - btnSize.width) / 2, y: (size.height - btnSize.height) / 2)
        let btnFrame = CGRect(origin: btnOrigin, size: btnSize)
        stopButton.frame = btnFrame
    }

    public func setProgress(value: Float, withAnimation animated: Bool) {
        guard Float(0.0) <= value && value <= Float(1.0) else { return }

        let oldValue = self.progress
        self.progress = value

        if animated {
            // FIXME: animation does not work: no animation happens.
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 0.3
            animation.fromValue = CGFloat(oldValue)
            animation.toValue = CGFloat(self.progress)
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.isRemovedOnCompletion = false
            progressLayer.add(animation, forKey: "animationProgress")
        } else {
            progressLayer.strokeEnd = CGFloat(self.progress)
        }
    }
}
