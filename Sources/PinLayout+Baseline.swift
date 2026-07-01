//  Copyright (c) 2026 Luc Dion
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

/// The way to align the text is by the first character or the last.
public enum BaselineAlignment {
    case first
    case last
}

/// Allows PinLayout to add the `baseline` method.
/// This protocol should be implemented by all view objects that have text inside, and with which we want to align the baseline.
public protocol PinBaselineable: AnyObject {
    /// The distance from the top of the view inscribed in the specified rectangle to the baseline.
    func pinBaselineFromTop(size: CGSize, alignment: BaselineAlignment) -> CGFloat
}

extension PinLayout {
    /// Allows you to attach the baseline of one view to another.
    /// For example:
    /// ```
    /// label1.pin.left(64.0).right(150.0).top(64.0).sizeToFit(.width)
    /// label2.pin.left(150.0).right(64.0).baseline(label1).sizeToFit(.width)
    /// ```
    /// By default, first character alignment is used. But you can change it.:
    /// ```
    /// label2.pin
    ///     .left(150.0)
    ///     .right(64.0)
    ///     .baseline(label1, alignment: .last, to: .last)
    ///     .sizeToFit(.width)
    /// ```
    ///
    /// - Parameters:
    ///   - refView: The view relative to which it is necessary to align this
    ///   - alignment: How should I align my view by the first or last character?
    ///   - toAlignment: What should the view be aligned relative to - relative to the first or last character of another view
    @discardableResult
    public func baseline(_ refView: PinView, alignment: BaselineAlignment = .first, to toAlignment: BaselineAlignment = .first) -> PinLayout {
        switch toAlignment {
        case .first:
            return baseline(to: VerticalEdgeImpl(view: refView, type: .firstBaseline), alignment: alignment)
        case .last:
            return baseline(to: VerticalEdgeImpl(view: refView, type: .lastBaseline), alignment: alignment)
        }
    }

    @discardableResult
    private func baseline(to edge: VerticalEdge, alignment: BaselineAlignment) -> PinLayout {
        func context() -> String { relativeEdgeContext(method: "baseline", edge: edge) }
        guard let refBaselineY = computeCoordinate(forEdge: edge, context) else {
            return self
        }
        guard let myView = view as? PinBaselineable else {
            setCenter(.zero, context)
            return self
        }

        setTop(refBaselineY, context)
        setBaseline({ [unowned myView] size in
            myView.pinBaselineFromTop(size: size, alignment: alignment)
        }, context)

        return self
    }
}


// MARK: - baseline calculations for basic types

// TODO: NEED adaptive to attributed

#if os(iOS) || os(tvOS)

extension UILabel: PinBaselineable {
    public func pinBaselineFromTop(size: CGSize, alignment: BaselineAlignment) -> CGFloat {
        let baselineOffset: CGFloat?
        if let attributedText {
            baselineOffset = calculateBaselineOffset(attributedText: attributedText, size: size, alignment: alignment)
        } else if let font {
            let attributedText = makeAttributedString(for: text ?? "", font: font)
            baselineOffset = calculateBaselineOffset(attributedText: attributedText, size: size, alignment: alignment)
        } else {
            baselineOffset = nil
        }

        return baselineOffset ?? bounds.midY
    }
}

extension UITextField: PinBaselineable {
    public func pinBaselineFromTop(size: CGSize, alignment: BaselineAlignment) -> CGFloat {
        let baselineOffset: CGFloat?
        if let attributedText {
            baselineOffset = calculateBaselineOffset(attributedText: attributedText, size: size, alignment: alignment)
        } else if let font {
            let attributedText = makeAttributedString(for: text ?? "", font: font)
            baselineOffset = calculateBaselineOffset(attributedText: attributedText, size: size, alignment: alignment)
        } else {
            baselineOffset = nil
        }

        return baselineOffset ?? bounds.midY
    }
}

extension UIButton: PinBaselineable {
    public func pinBaselineFromTop(size: CGSize, alignment: BaselineAlignment) -> CGFloat {
        guard let label = titleLabel else {
            return bounds.midY
        }

        let attributedString: NSAttributedString? = if let attributedText = label.attributedText {
            attributedText
        } else if let font = label.font {
            makeAttributedString(for: label.text ?? "", font: font)
        } else {
            nil
        }
        guard let attributedString else {
            return bounds.midY
        }

        let boundingSize = label.calculateBoundingSize(size: size)
        let topOffset = (size.height - boundingSize.height) * 0.5

        switch alignment {
        case .first:
            let ascender = firstCharacterFontAscender(for: attributedString)
            if let ascender {
                return topOffset + ascender
            }
        case .last:
            let descender = lastCharacterFontDescender(for: attributedString)
            if let descender {
                return topOffset + boundingSize.height + descender
            }
        }

        return bounds.midY
    }
}

extension UIView {
    fileprivate func makeAttributedString(for text: String, font: UIFont) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [
            .font: font
        ])
    }

    fileprivate func calculateBaselineOffset(attributedText: NSAttributedString, size: CGSize, alignment: BaselineAlignment) -> CGFloat? {
        if attributedText.string.isEmpty {
            return 0.0
        }

        switch alignment {
        case .first:
            let ascender = firstCharacterFontAscender(for: attributedText)
            return ascender
        case .last:
            let boundingSize = calculateBoundingSize(size: size)
            let descender = lastCharacterFontDescender(for: attributedText)
            if let descender {
                return boundingSize.height + descender
            }
            return nil
        }
    }

    fileprivate func calculateBoundingSize(size: CGSize) -> CGSize {
        let constraintSize = CGSize(
            width: size.width > 0 ? size.width : CGFloat.greatestFiniteMagnitude,
            height: size.height > 0 ? size.height : CGFloat.greatestFiniteMagnitude
        )

        return systemLayoutSizeFitting(constraintSize,
                                       withHorizontalFittingPriority: .required,
                                       verticalFittingPriority: .fittingSizeLevel)
    }

    fileprivate func firstCharacterFontAscender(for attributedString: NSAttributedString) -> CGFloat? {
        let firstCharFont = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        return firstCharFont?.ascender
    }

    fileprivate func lastCharacterFontDescender(for attributedString: NSAttributedString) -> CGFloat? {
        let lastCharIndex = max(0, attributedString.length - 1)
        let lastCharFont = attributedString.attribute(.font, at: lastCharIndex, effectiveRange: nil) as? UIFont

        return lastCharFont?.descender
    }
}

#endif
