//
//  PinLayout+Baseline.swift
//  PinLayout
//
//  Created by Alexander Ivlev on 30.06.2026.
//


#if os(iOS) || os(tvOS)
import UIKit
#endif

public enum BaselineStyle {
    case first
    case last
}

/// Позволяет PinLayout добавить метод `baseline`.
/// Этот протокол должны реализовать все вью объекты, у которых внутри есть текст, и с которыми мы хотим выравнивать baseline.
public protocol PinBaselineable: AnyObject {
    /// Расстояние в поинтах от верха bounds вьюхи до первого или последнего baseline текста в зависимости от стиля.
    func pinBaselineFromTop(_ bounds: CGRect, style: BaselineStyle) -> CGFloat
}

#if os(iOS) || os(tvOS)
extension PinLayout {
    @discardableResult
    public func baseline(_ refView: PinView, style: BaselineStyle = .first, to toStyle: BaselineStyle = .first) -> PinLayout {
        switch toStyle {
        case .first:
            return baseline(to: VerticalEdgeImpl(view: refView, type: .firstBaseline), style: style)
        case .last:
            return baseline(to: VerticalEdgeImpl(view: refView, type: .lastBaseline), style: style)
        }
    }

    @discardableResult
    private func baseline(to edge: VerticalEdge, style: BaselineStyle) -> PinLayout {
        func context() -> String { relativeEdgeContext(method: "baseline", edge: edge) }
        guard let refBaselineY = computeCoordinate(forEdge: edge, context) else {
            return self
        }
        guard let myView = view as? PinBaselineable else {
            setCenter(.zero, context)
            return self
        }

        setTop(refBaselineY, context)
        setBaseline({ [unowned myView] bounds in myView.pinBaselineFromTop(bounds, style: style) }, context)

        return self
    }
}


// MARK: - расчеты baseline для базовых типов

// TODO: расчеты пока тупые - считают, что font одинаковый, в общем не работает для attrubuted

extension UILabel: PinBaselineable {
    public func pinBaselineFromTop(_ bounds: CGRect, style: BaselineStyle) -> CGFloat {
        let constraintRect = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let textBoxSize = self.systemLayoutSizeFitting(constraintRect)
        return baseline(font: font, height: textBoxSize.height, style: style)
    }
}

extension UITextField: PinBaselineable {
    public func pinBaselineFromTop(_ bounds: CGRect, style: BaselineStyle) -> CGFloat {
        guard let font else {
            return bounds.midY
        }

        let constraintRect = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let textBoxSize = self.systemLayoutSizeFitting(constraintRect)

        return baseline(font: font, height: textBoxSize.height, style: style)
    }
}

extension UIButton: PinBaselineable {
    public func pinBaselineFromTop(_ bounds: CGRect, style: BaselineStyle) -> CGFloat {
        guard let label = titleLabel, let font = label.font else {
            return bounds.midY
        }

        let constraintRect = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let textBoxSize = label.systemLayoutSizeFitting(constraintRect)
        let topOffset = (bounds.height - textBoxSize.height) * 0.5

        return topOffset + baseline(font: font, height: textBoxSize.height, style: style)
    }
}

private func baseline(font: UIFont, height: CGFloat, style: BaselineStyle) -> CGFloat {
    switch style {
    case .first:
        return font.ascender
    case .last:
        let linesCount = max(1, ceil((height - 1) / font.lineHeight))
        return ((linesCount - 1) * font.lineHeight) + font.ascender
    }
}

#endif
