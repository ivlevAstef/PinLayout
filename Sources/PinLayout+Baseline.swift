//
//  PinLayout+Baseline.swift
//  PinLayout
//
//  Created by Alexander Ivlev on 30.06.2026.
//


#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Позволяет PinLayout добавить метод `baseline`.
/// Этот протокол должны реализовать все вью объекты, у которых внутри есть текст, и с которыми мы хотим выравнивать baseline.
public protocol PinBaselineable {
    /// Расстояние в поинтах от верха bounds вьюхи до первого baseline текста.
    var pinFirstBaselineFromTop: CGFloat { get }

    /// Расстояние в поинтах от верха bounds вьюхи до последнего baseline текста.
    var pinLastBaselineFromTop: CGFloat { get }
}

#if os(iOS) || os(tvOS)
extension PinLayout {
    @discardableResult
    public func firstBaseline(_ refView: PinView) -> PinLayout {
        firstBaseline(to: VerticalEdgeImpl(view: refView, type: .firstBaseline))
    }

    @discardableResult
    public func lastBaseline(_ refView: PinView) -> PinLayout {
        lastBaseline(to: VerticalEdgeImpl(view: refView, type: .lastBaseline))
    }

    @discardableResult
    public func firstBaseline(to edge: VerticalEdge) -> PinLayout {
        func context() -> String { relativeEdgeContext(method: "firstBaseline", edge: edge) }
        guard let refBaselineY = computeCoordinate(forEdge: edge, context) else {
            return self
        }
        guard let myView = view as? PinBaselineable else {
            setCenter(.zero, context)
            return self
        }

        setTop(refBaselineY - myView.pinFirstBaselineFromTop, context)
        return self
    }

    @discardableResult
    public func lastBaseline(to edge: VerticalEdge) -> PinLayout {
        func context() -> String { relativeEdgeContext(method: "lastBaseline", edge: edge) }
        guard let refBaselineY = computeCoordinate(forEdge: edge, context) else {
            return self
        }
        guard let myView = view as? PinBaselineable else {
            setCenter(.zero, context)
            return self
        }

        setTop(refBaselineY - myView.pinLastBaselineFromTop, context)
        return self
    }
}


// MARK: - расчеты baseline для базовых типов

extension UILabel: PinBaselineable {
    public var pinFirstBaselineFromTop: CGFloat {
        let lines = numberOfLines == 0 ? 1 : numberOfLines
        let textRect = textRect(forBounds: bounds, limitedToNumberOfLines: lines)
        return textRect.minY + font.ascender
    }

    public var pinLastBaselineFromTop: CGFloat {
        let lines = numberOfLines == 0 ? 1 : numberOfLines
        let textRect = textRect(forBounds: bounds, limitedToNumberOfLines: lines)
        return textRect.minY + font.ascender
    }
}

extension UITextView: PinBaselineable {
    public var pinFirstBaselineFromTop: CGFloat {
        guard let font else {
            return textContainerInset.top
        }
        return textContainerInset.top + font.ascender
    }

    public var pinLastBaselineFromTop: CGFloat {
        guard let font else {
            return textContainerInset.top
        }
        return textContainerInset.top + font.ascender
    }
}

extension UITextField: PinBaselineable {
    public var pinFirstBaselineFromTop: CGFloat {
        guard let font else {
            return bounds.midY
        }
        return textRect(forBounds: bounds).minY + font.ascender
    }

    public var pinLastBaselineFromTop: CGFloat {
        guard let font else {
            return bounds.midY
        }
        return textRect(forBounds: bounds).minY + font.ascender
    }
}

extension UIButton: PinBaselineable {
    public var pinFirstBaselineFromTop: CGFloat {
        guard let label = titleLabel, let font = label.font else {
            return bounds.midY
        }
        let rect = label.textRect(forBounds: label.bounds,limitedToNumberOfLines: 1)
        return label.frame.minY + rect.minY + font.ascender
    }

    public var pinLastBaselineFromTop: CGFloat {
        guard let label = titleLabel, let font = label.font else {
            return bounds.midY
        }
        let rect = label.textRect(forBounds: label.bounds,limitedToNumberOfLines: 1)
        return label.frame.minY + rect.minY + font.ascender
    }
}



#endif
