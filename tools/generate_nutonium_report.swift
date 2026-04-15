import Foundation
import AppKit

let pageWidth: CGFloat = 595.0
let pageHeight: CGFloat = 842.0
let marginLeft: CGFloat = 64.0
let marginRight: CGFloat = 64.0
let topMargin: CGFloat = 74.0
let bottomMargin: CGFloat = 64.0
let contentWidth: CGFloat = pageWidth - marginLeft - marginRight

let forest = NSColor(calibratedRed: 0.09, green: 0.20, blue: 0.15, alpha: 1.0)
let forestDeep = NSColor(calibratedRed: 0.06, green: 0.15, blue: 0.11, alpha: 1.0)
let brass = NSColor(calibratedRed: 0.78, green: 0.64, blue: 0.37, alpha: 1.0)
let parchment = NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
let canvas = NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.83, alpha: 1.0)
let ink = NSColor(calibratedRed: 0.12, green: 0.11, blue: 0.09, alpha: 1.0)
let muted = NSColor(calibratedRed: 0.43, green: 0.40, blue: 0.37, alpha: 1.0)
let success = NSColor(calibratedRed: 0.18, green: 0.48, blue: 0.34, alpha: 1.0)
let warning = NSColor(calibratedRed: 0.75, green: 0.50, blue: 0.13, alpha: 1.0)
let danger = NSColor(calibratedRed: 0.71, green: 0.28, blue: 0.24, alpha: 1.0)

func serif(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> NSFont {
    let names: [String]
    if bold && italic {
        names = ["Times New Roman Bold Italic", "Times-BoldItalic", "Georgia-BoldItalic", "Baskerville-BoldItalic"]
    } else if bold {
        names = ["Times New Roman Bold", "Times-Bold", "Georgia-Bold", "Baskerville-Bold"]
    } else if italic {
        names = ["Times New Roman Italic", "Times-Italic", "Georgia-Italic", "Baskerville-Italic"]
    } else {
        names = ["Times New Roman", "Times-Roman", "Georgia", "Baskerville"]
    }
    for name in names {
        if let font = NSFont(name: name, size: size) {
            return font
        }
    }
    return NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
}

func sans(_ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    let names: [String]
    switch weight {
    case .bold, .semibold, .heavy:
        names = ["Helvetica Neue Bold", "Avenir Next Demi Bold", "Helvetica-Bold"]
    case .medium:
        names = ["Helvetica Neue Medium", "Avenir Next Medium", "Helvetica"]
    default:
        names = ["Helvetica Neue", "Avenir Next Regular", "Helvetica"]
    }
    for name in names {
        if let font = NSFont(name: name, size: size) {
            return font
        }
    }
    return NSFont.systemFont(ofSize: size, weight: weight)
}

struct PageStyle {
    let headerTitle: String?
    let showFooter: Bool
    let tintedBackground: Bool
}

final class PDFBuilder {
    private let data = NSMutableData()
    private let context: CGContext
    private var currentGraphicsContext: NSGraphicsContext?
    private var isPageOpen = false
    private var pageNumber = 0
    private var cursorTop: CGFloat = topMargin
    private var style = PageStyle(headerTitle: nil, showFooter: true, tintedBackground: false)

    init() {
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            fatalError("Unable to create PDF context")
        }
        self.context = context
    }

    func finalize(to outputURL: URL) throws {
        finishPage()
        context.closePDF()
        try data.write(to: outputURL)
    }

    func beginPage(_ newStyle: PageStyle) {
        finishPage()
        style = newStyle
        pageNumber += 1
        cursorTop = topMargin
        context.beginPDFPage(nil)
        isPageOpen = true

        let backgroundColor = style.tintedBackground ? parchment.cgColor : NSColor.white.cgColor
        context.saveGState()
        context.setFillColor(backgroundColor)
        context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        context.restoreGState()

        let graphics = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        currentGraphicsContext = graphics

        if let headerTitle = style.headerTitle {
            drawHeader(title: headerTitle)
        }
    }

    func finishPage() {
        guard isPageOpen else { return }
        if style.showFooter {
            drawFooter()
        }
        currentGraphicsContext = nil
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
        isPageOpen = false
    }

    func forcePageBreak(_ newStyle: PageStyle? = nil) {
        beginPage(newStyle ?? style)
    }

    func availableHeight() -> CGFloat {
        return pageHeight - bottomMargin - cursorTop
    }

    func ensureSpace(_ needed: CGFloat) {
        if needed > availableHeight() {
            beginPage(style)
        }
    }

    func addSpacing(_ value: CGFloat) {
        cursorTop += value
    }

    func drawParagraph(
        _ text: String,
        font: NSFont = serif(12.5),
        color: NSColor = ink,
        width: CGFloat = contentWidth,
        x: CGFloat = marginLeft,
        alignment: NSTextAlignment = .justified,
        lineSpacing: CGFloat = 3.0,
        paragraphSpacing: CGFloat = 0.0,
        spacingAfter: CGFloat = 12.0,
        firstLineHeadIndent: CGFloat = 0.0,
        headIndent: CGFloat = 0.0,
        tailIndent: CGFloat = 0.0
    ) {
        let attr = attributedText(
            text,
            font: font,
            color: color,
            alignment: alignment,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing,
            firstLineHeadIndent: firstLineHeadIndent,
            headIndent: headIndent,
            tailIndent: tailIndent
        )
        let height = measuredHeight(for: attr, width: width)
        ensureSpace(height + spacingAfter)
        let rect = rectFromTop(x: x, top: cursorTop, width: width, height: height)
        attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        cursorTop += height + spacingAfter
    }

    func drawCenteredParagraph(
        _ text: String,
        font: NSFont,
        color: NSColor = ink,
        width: CGFloat = contentWidth,
        top: CGFloat? = nil,
        spacingAfter: CGFloat = 10.0,
        lineSpacing: CGFloat = 2.0
    ) {
        if let top { cursorTop = top }
        drawParagraph(
            text,
            font: font,
            color: color,
            width: width,
            x: (pageWidth - width) / 2,
            alignment: .center,
            lineSpacing: lineSpacing,
            spacingAfter: spacingAfter
        )
    }

    func drawBulletList(_ items: [String], bulletColor: NSColor = forest) {
        for item in items {
            drawBullet(item, bulletColor: bulletColor)
        }
    }

    func drawBullet(_ text: String, bulletColor: NSColor = forest) {
        let bulletWidth: CGFloat = 14
        let bulletTop = cursorTop + 4
        ensureSpace(26)
        context.saveGState()
        context.setFillColor(bulletColor.cgColor)
        let bulletRect = CGRect(x: marginLeft + 2, y: pageHeight - bulletTop - 6, width: 6, height: 6)
        context.fillEllipse(in: bulletRect)
        context.restoreGState()
        drawParagraph(
            text,
            font: serif(12.5),
            color: ink,
            width: contentWidth - bulletWidth,
            x: marginLeft + bulletWidth,
            alignment: .justified,
            lineSpacing: 3.0,
            spacingAfter: 9.0
        )
    }

    func drawNumberedList(_ items: [String]) {
        for (index, item) in items.enumerated() {
            let number = "\(index + 1)."
            let numberAttr = attributedText(number, font: sans(11.5, weight: .bold), color: forest, alignment: .left)
            let numberHeight = measuredHeight(for: numberAttr, width: 20)
            ensureSpace(numberHeight + 10)
            let numberRect = rectFromTop(x: marginLeft, top: cursorTop + 1, width: 20, height: numberHeight)
            numberAttr.draw(with: numberRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
            drawParagraph(
                item,
                font: serif(12.5),
                color: ink,
                width: contentWidth - 24,
                x: marginLeft + 24,
                alignment: .justified,
                lineSpacing: 3.0,
                spacingAfter: 9.0
            )
        }
    }

    func drawSectionTitle(_ text: String, accent: NSColor = forest) {
        let needed: CGFloat = 34
        ensureSpace(needed)
        let title = attributedText(text.uppercased(), font: sans(11.5, weight: .bold), color: accent, alignment: .left)
        let height = measuredHeight(for: title, width: contentWidth)
        let rect = rectFromTop(x: marginLeft, top: cursorTop, width: contentWidth, height: height)
        title.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        cursorTop += height + 5
        context.saveGState()
        context.setFillColor(accent.withAlphaComponent(0.85).cgColor)
        context.fill(CGRect(x: marginLeft, y: pageHeight - cursorTop - 2, width: 86, height: 2))
        context.restoreGState()
        cursorTop += 12
    }

    func drawChapterHeading(number: String, title: String, subtitle: String) {
        drawSectionTitle("Chapter \(number)", accent: brass)
        drawParagraph(
            title,
            font: serif(24, bold: true),
            color: ink,
            width: contentWidth,
            x: marginLeft,
            alignment: .left,
            lineSpacing: 2.0,
            spacingAfter: 10
        )
        drawParagraph(
            subtitle,
            font: serif(12.5, italic: true),
            color: muted,
            width: contentWidth,
            x: marginLeft,
            alignment: .left,
            lineSpacing: 2.0,
            spacingAfter: 18
        )
    }

    func drawCallout(title: String, body: String, tint: NSColor = canvas) {
        let titleAttr = attributedText(title, font: sans(11.5, weight: .bold), color: forest)
        let bodyAttr = attributedText(body, font: serif(12.0), color: ink, alignment: .justified, lineSpacing: 3.0)
        let titleHeight = measuredHeight(for: titleAttr, width: contentWidth - 28)
        let bodyHeight = measuredHeight(for: bodyAttr, width: contentWidth - 28)
        let totalHeight = titleHeight + bodyHeight + 24
        ensureSpace(totalHeight + 10)
        let box = rectFromTop(x: marginLeft, top: cursorTop, width: contentWidth, height: totalHeight)
        let path = NSBezierPath(roundedRect: box, xRadius: 14, yRadius: 14)
        tint.setFill()
        path.fill()
        forest.withAlphaComponent(0.10).setStroke()
        path.lineWidth = 1
        path.stroke()
        titleAttr.draw(with: rectFromTop(x: marginLeft + 14, top: cursorTop + 12, width: contentWidth - 28, height: titleHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
        bodyAttr.draw(with: rectFromTop(x: marginLeft + 14, top: cursorTop + 12 + titleHeight + 6, width: contentWidth - 28, height: bodyHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
        cursorTop += totalHeight + 12
    }

    func drawTwoColumnRows(title: String, rows: [(String, String)]) {
        drawSectionTitle(title, accent: forest)
        let leftWidth: CGFloat = 145
        let rightWidth: CGFloat = contentWidth - leftWidth - 18
        for (label, value) in rows {
            let labelAttr = attributedText(label, font: sans(11.5, weight: .bold), color: forest)
            let valueAttr = attributedText(value, font: serif(12.0), color: ink, alignment: .justified, lineSpacing: 3.0)
            let labelHeight = measuredHeight(for: labelAttr, width: leftWidth)
            let valueHeight = measuredHeight(for: valueAttr, width: rightWidth)
            let rowHeight = max(labelHeight, valueHeight) + 18
            ensureSpace(rowHeight + 6)
            let rowRect = rectFromTop(x: marginLeft, top: cursorTop, width: contentWidth, height: rowHeight)
            let rowPath = NSBezierPath(roundedRect: rowRect, xRadius: 10, yRadius: 10)
            NSColor.white.setFill()
            rowPath.fill()
            forest.withAlphaComponent(0.08).setStroke()
            rowPath.lineWidth = 1
            rowPath.stroke()
            labelAttr.draw(with: rectFromTop(x: marginLeft + 12, top: cursorTop + 9, width: leftWidth, height: labelHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
            valueAttr.draw(with: rectFromTop(x: marginLeft + 12 + leftWidth + 12, top: cursorTop + 9, width: rightWidth, height: valueHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
            cursorTop += rowHeight + 8
        }
    }

    func drawSignatureRow(_ left: String, _ right: String) {
        let lineWidth: CGFloat = 170
        let needed: CGFloat = 60
        ensureSpace(needed)
        let y = pageHeight - cursorTop - 18
        context.saveGState()
        context.setStrokeColor(muted.cgColor)
        context.setLineWidth(0.8)
        context.move(to: CGPoint(x: marginLeft, y: y))
        context.addLine(to: CGPoint(x: marginLeft + lineWidth, y: y))
        context.move(to: CGPoint(x: pageWidth - marginRight - lineWidth, y: y))
        context.addLine(to: CGPoint(x: pageWidth - marginRight, y: y))
        context.strokePath()
        context.restoreGState()
        drawParagraph(left, font: sans(10.5), color: muted, width: lineWidth, x: marginLeft, alignment: .center, spacingAfter: 0)
        cursorTop -= 10
        drawParagraph(right, font: sans(10.5), color: muted, width: lineWidth, x: pageWidth - marginRight - lineWidth, alignment: .center, spacingAfter: 24)
    }

    func drawArchitectureDiagram() {
        let totalHeight: CGFloat = 250
        ensureSpace(totalHeight + 10)
        drawSectionTitle("Architecture Diagram", accent: brass)
        let boxWidth = contentWidth
        let boxHeight: CGFloat = 42
        let gap: CGFloat = 14
        let x = marginLeft
        let titles = [
            ("User Roles", "Customer, retailer, and wholesaler entry points", brass.withAlphaComponent(0.18), brass),
            ("Presentation Layer", "Auth, social feed, cart, map, profile, and inventory screens", canvas, forest),
            ("Service Layer", "MarketplaceService, OTP sender, recovery logic, and navigation orchestration", NSColor.white, forest),
            ("Cloud and External Services", "Firebase Auth, Cloud Firestore, OpenStreetMap tiles, Google Sign-In, SMTP", canvas, forestDeep),
        ]
        for (index, item) in titles.enumerated() {
            let top = cursorTop + CGFloat(index) * (boxHeight + gap)
            drawDiagramBox(x: x, top: top, width: boxWidth, height: boxHeight, title: item.0, subtitle: item.1, fill: item.2, stroke: item.3)
            if index < titles.count - 1 {
                let arrowY = pageHeight - (top + boxHeight + gap / 2)
                context.saveGState()
                context.setStrokeColor(forest.withAlphaComponent(0.4).cgColor)
                context.setLineWidth(1.2)
                let midX = x + boxWidth / 2
                context.move(to: CGPoint(x: midX, y: arrowY + 4))
                context.addLine(to: CGPoint(x: midX, y: arrowY - 8))
                context.strokePath()
                context.move(to: CGPoint(x: midX - 4, y: arrowY - 4))
                context.addLine(to: CGPoint(x: midX, y: arrowY - 8))
                context.addLine(to: CGPoint(x: midX + 4, y: arrowY - 4))
                context.strokePath()
                context.restoreGState()
            }
        }
        cursorTop += totalHeight
    }

    func drawFirestoreDiagram() {
        let totalHeight: CGFloat = 290
        ensureSpace(totalHeight + 10)
        drawSectionTitle("Firestore Collection Map", accent: brass)

        let top = cursorTop + 8
        let boxWidth: CGFloat = 138
        let leftX = marginLeft
        let centerX = marginLeft + 164
        let rightX = marginLeft + 328

        drawDiagramBox(x: centerX, top: top, width: boxWidth, height: 44, title: "users", subtitle: "role, profile completeness, timestamps", fill: canvas, stroke: forest)
        drawDiagramBox(x: leftX, top: top + 84, width: boxWidth, height: 48, title: "retailers", subtitle: "shop data, categories, GST, location", fill: NSColor.white, stroke: forest)
        drawDiagramBox(x: rightX, top: top + 84, width: boxWidth, height: 48, title: "wholesalers", subtitle: "company data, PAN/GST, business location", fill: NSColor.white, stroke: forest)
        drawDiagramBox(x: leftX, top: top + 176, width: boxWidth, height: 48, title: "social_feed", subtitle: "market timeline for offers and events", fill: parchment, stroke: brass)
        drawDiagramBox(x: rightX, top: top + 176, width: boxWidth, height: 48, title: "posts", subtitle: "parallel persistence of trade content", fill: parchment, stroke: brass)
        drawDiagramBox(x: centerX, top: top + 236, width: boxWidth, height: 40, title: "utility collections", subtitle: "user_posts and post_analytics", fill: canvas, stroke: forest)

        drawArrow(from: CGPoint(x: centerX + boxWidth / 2, y: top + 44), to: CGPoint(x: leftX + boxWidth / 2, y: top + 84))
        drawArrow(from: CGPoint(x: centerX + boxWidth / 2, y: top + 44), to: CGPoint(x: rightX + boxWidth / 2, y: top + 84))
        drawArrow(from: CGPoint(x: leftX + boxWidth / 2, y: top + 132), to: CGPoint(x: leftX + boxWidth / 2, y: top + 176))
        drawArrow(from: CGPoint(x: rightX + boxWidth / 2, y: top + 132), to: CGPoint(x: rightX + boxWidth / 2, y: top + 176))
        drawArrow(from: CGPoint(x: leftX + boxWidth, y: top + 200), to: CGPoint(x: rightX, y: top + 200))
        drawArrow(from: CGPoint(x: centerX + boxWidth / 2, y: top + 224), to: CGPoint(x: centerX + boxWidth / 2, y: top + 236))

        cursorTop += totalHeight
    }

    private func drawHeader(title: String) {
        let headerTop: CGFloat = 36
        let titleAttr = attributedText(title.uppercased(), font: sans(10.0, weight: .bold), color: forest)
        let dateAttr = attributedText("Nutonium report snapshot", font: sans(9.5), color: muted, alignment: .right)
        let titleHeight = measuredHeight(for: titleAttr, width: 240)
        titleAttr.draw(with: rectFromTop(x: marginLeft, top: headerTop, width: 240, height: titleHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
        dateAttr.draw(with: rectFromTop(x: pageWidth - marginRight - 180, top: headerTop, width: 180, height: titleHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
        context.saveGState()
        context.setStrokeColor(brass.withAlphaComponent(0.7).cgColor)
        context.setLineWidth(0.8)
        let y = pageHeight - 54
        context.move(to: CGPoint(x: marginLeft, y: y))
        context.addLine(to: CGPoint(x: pageWidth - marginRight, y: y))
        context.strokePath()
        context.restoreGState()
        cursorTop = 72
    }

    private func drawFooter() {
        let footerAttr = attributedText("Page \(pageNumber)", font: sans(9.5), color: muted, alignment: .center)
        let footerHeight = measuredHeight(for: footerAttr, width: 100)
        footerAttr.draw(with: CGRect(x: (pageWidth - 100) / 2, y: 24, width: 100, height: footerHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
    }

    private func drawDiagramBox(x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, title: String, subtitle: String, fill: NSColor, stroke: NSColor) {
        let rect = rectFromTop(x: x, top: top, width: width, height: height)
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        fill.setFill()
        path.fill()
        stroke.withAlphaComponent(0.25).setStroke()
        path.lineWidth = 1
        path.stroke()
        let titleAttr = attributedText(title, font: sans(10.5, weight: .bold), color: stroke, alignment: .center)
        let subtitleAttr = attributedText(subtitle, font: sans(8.8), color: muted, alignment: .center, lineSpacing: 1.5)
        let titleHeight = measuredHeight(for: titleAttr, width: width - 16)
        let subtitleHeight = measuredHeight(for: subtitleAttr, width: width - 16)
        titleAttr.draw(with: rectFromTop(x: x + 8, top: top + 8, width: width - 16, height: titleHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
        subtitleAttr.draw(with: rectFromTop(x: x + 8, top: top + 8 + titleHeight + 3, width: width - 16, height: subtitleHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
    }

    private func drawArrow(from topPoint: CGPoint, to topDestination: CGPoint) {
        let fromPoint = CGPoint(x: topPoint.x, y: pageHeight - topPoint.y)
        let toPoint = CGPoint(x: topDestination.x, y: pageHeight - topDestination.y)
        context.saveGState()
        context.setStrokeColor(forest.withAlphaComponent(0.40).cgColor)
        context.setLineWidth(1.0)
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        context.strokePath()
        let dx = toPoint.x - fromPoint.x
        let dy = toPoint.y - fromPoint.y
        let angle = atan2(dy, dx)
        let headLength: CGFloat = 6
        let left = CGPoint(x: toPoint.x - headLength * cos(angle - .pi / 6), y: toPoint.y - headLength * sin(angle - .pi / 6))
        let right = CGPoint(x: toPoint.x - headLength * cos(angle + .pi / 6), y: toPoint.y - headLength * sin(angle + .pi / 6))
        context.move(to: toPoint)
        context.addLine(to: left)
        context.move(to: toPoint)
        context.addLine(to: right)
        context.strokePath()
        context.restoreGState()
    }

    private func attributedText(
        _ text: String,
        font: NSFont,
        color: NSColor,
        alignment: NSTextAlignment = .left,
        lineSpacing: CGFloat = 2.0,
        paragraphSpacing: CGFloat = 0.0,
        firstLineHeadIndent: CGFloat = 0.0,
        headIndent: CGFloat = 0.0,
        tailIndent: CGFloat = 0.0
    ) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.firstLineHeadIndent = firstLineHeadIndent
        style.headIndent = headIndent
        style.tailIndent = tailIndent
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style,
        ])
    }

    private func measuredHeight(for attr: NSAttributedString, width: CGFloat) -> CGFloat {
        let rect = attr.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading])
        return ceil(rect.height)
    }

    private func rectFromTop(x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: x, y: pageHeight - top - height, width: width, height: height)
    }
}

let builder = PDFBuilder()
let bodyStyle = PageStyle(headerTitle: "Nutonium Project Report", showFooter: true, tintedBackground: false)
let prelimStyle = PageStyle(headerTitle: nil, showFooter: true, tintedBackground: false)
let coverStyle = PageStyle(headerTitle: nil, showFooter: false, tintedBackground: true)

func drawCoverPage() {
    builder.beginPage(coverStyle)

    let bannerRect = CGRect(x: 0, y: pageHeight - 160, width: pageWidth, height: 160)
    let path = NSBezierPath(rect: bannerRect)
    forest.setFill()
    path.fill()

    builder.drawCenteredParagraph(
        "Nutonium: A Location-Aware Marketplace and Trade Coordination Platform for Retailers, Wholesalers, and Customers",
        font: serif(25, bold: true),
        color: NSColor.white,
        width: 420,
        top: 66,
        spacingAfter: 16,
        lineSpacing: 3.0
    )

    builder.drawCenteredParagraph(
        "Mini Project Report",
        font: sans(13.5, weight: .bold),
        color: brass,
        width: 240,
        spacingAfter: 10
    )

    builder.drawCenteredParagraph(
        "Prepared from the current Flutter and Firebase implementation snapshot of the Nutonium application",
        font: serif(12.5, italic: true),
        color: parchment,
        width: 360,
        spacingAfter: 26
    )

    let emblemCenter = CGPoint(x: pageWidth / 2, y: pageHeight - 318)
    builder.addSpacing(8)
    if let context = NSGraphicsContext.current?.cgContext {
        context.saveGState()
        context.setFillColor(canvas.cgColor)
        context.fillEllipse(in: CGRect(x: emblemCenter.x - 66, y: emblemCenter.y - 66, width: 132, height: 132))
        context.setFillColor(forest.cgColor)
        context.fillEllipse(in: CGRect(x: emblemCenter.x - 52, y: emblemCenter.y - 52, width: 104, height: 104))
        context.setStrokeColor(brass.cgColor)
        context.setLineWidth(4)
        context.strokeEllipse(in: CGRect(x: emblemCenter.x - 66, y: emblemCenter.y - 66, width: 132, height: 132))
        context.restoreGState()
    }

    let emblemTitle = NSAttributedString(string: "N", attributes: [
        .font: serif(42, bold: true),
        .foregroundColor: NSColor.white,
    ])
    emblemTitle.draw(at: CGPoint(x: emblemCenter.x - 16, y: emblemCenter.y - 26))
    let emblemSub = NSAttributedString(string: "MARKET", attributes: [
        .font: sans(10.5, weight: .bold),
        .foregroundColor: brass,
    ])
    emblemSub.draw(at: CGPoint(x: emblemCenter.x - 24, y: emblemCenter.y - 44))

    builder.drawCenteredParagraph("Submitted by", font: serif(13.5, italic: true), color: muted, width: 220, top: 428, spacingAfter: 8)
    builder.drawCenteredParagraph("NUTONIUM DEVELOPMENT TEAM", font: serif(20, bold: true), color: ink, width: 360, spacingAfter: 4)
    builder.drawCenteredParagraph("(Institution, student names, and register numbers can be inserted before formal submission)", font: sans(10.8), color: muted, width: 400, spacingAfter: 20)

    builder.drawCenteredParagraph("Project Context", font: serif(13.5, italic: true), color: muted, width: 220, spacingAfter: 6)
    builder.drawCenteredParagraph("Flutter mobile application with Firebase Authentication, Cloud Firestore, map-based seller discovery, social trade feed, and a multi-seller cart workflow", font: serif(13.5), color: ink, width: 420, spacingAfter: 28, lineSpacing: 3.0)

    builder.drawCenteredParagraph("APRIL 2026", font: serif(18, bold: true), color: forest, width: 220, top: 720, spacingAfter: 8)
    builder.drawCenteredParagraph("Documentation draft generated from the active Nutonium codebase", font: sans(10.8), color: muted, width: 360, spacingAfter: 0)
}

func drawCertificatePage() {
    builder.beginPage(prelimStyle)
    builder.drawCenteredParagraph("CERTIFICATE", font: serif(24, bold: true), color: ink, width: 280, top: 84, spacingAfter: 20)
    builder.drawParagraph("This is to certify that the report titled \"Nutonium: A Location-Aware Marketplace and Trade Coordination Platform for Retailers, Wholesalers, and Customers\" is a structured documentation draft prepared from the current implementation snapshot of the Nutonium software project. The report consolidates the application architecture, feature modules, data model, user experience strategy, and current implementation status available in the project workspace on 5 April 2026.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("Because the repository does not contain formal academic submission metadata, institutional fields such as student register numbers, guide name, department, internal examiner approval, and organization seal should be inserted before the document is used for university submission or evaluation.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 24)
    builder.drawCallout(title: "Certification Scope", body: "The contents of this report reflect the current Flutter codebase, Firebase integration, shared marketplace services, map workflow, cart flow, and authentication screens present in the Nutonium project at the time of preparation.", tint: canvas)
    builder.addSpacing(200)
    builder.drawSignatureRow("Project Team / Submitter", "Guide / Reviewer")
}

func drawDeclarationPage() {
    builder.beginPage(prelimStyle)
    builder.drawCenteredParagraph("DECLARATION", font: serif(24, bold: true), color: ink, width: 280, top: 84, spacingAfter: 20)
    builder.drawParagraph("I/We hereby declare that this project report is prepared from the Nutonium application source code and related project assets available in the development workspace. The report is intended to convert the current implementation into an academic-style document for presentation, review, and further refinement.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("All third-party technologies, frameworks, SDKs, and packages used in the application are acknowledged in the references section. Any additional declaration format mandated by an institution, department, or project review board should be appended separately before submission.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 24)
    builder.drawCallout(title: "Basis of the Declaration", body: "The report is factual to the inspected codebase and does not claim features that are absent from the current implementation. Where future enhancements are discussed, they are identified explicitly as pending work.", tint: parchment)
    builder.addSpacing(210)
    builder.drawSignatureRow("Name and Signature of Submitter", "Date")
}

func drawAcknowledgementPage() {
    builder.beginPage(prelimStyle)
    builder.drawCenteredParagraph("ACKNOWLEDGEMENT", font: serif(24, bold: true), color: ink, width: 340, top: 84, spacingAfter: 20)
    builder.drawParagraph("The Nutonium project benefits directly from the Flutter framework, Firebase services, and a set of open-source packages that make rapid mobile application development feasible. The current implementation demonstrates how a modern mobile stack can combine authentication, data storage, geospatial discovery, cart aggregation, and curated visual design into a unified marketplace product.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("Acknowledgement is due to the maintainers of Flutter, Cloud Firestore, Firebase Authentication, flutter_map, Google Sign-In, the Mailer package, and Image Picker. Their documentation and libraries materially reduce the cost of prototyping and allow the project to focus on product behavior and user flow instead of low-level infrastructure concerns.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("The report also reflects repeated debugging and stabilization efforts across account creation, OTP verification, profile handling, navigation, cart layout, and map-driven discovery. That engineering work is part of what makes the current Nutonium snapshot suitable for documentation in report form.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 0)
}

func drawAbstractPage() {
    builder.beginPage(prelimStyle)
    builder.drawCenteredParagraph("ABSTRACT", font: serif(24, bold: true), color: ink, width: 240, top: 84, spacingAfter: 20)
    builder.drawParagraph("Nutonium is a location-aware digital marketplace prototype built with Flutter and Firebase. The application is designed to connect customers, retailers, and wholesalers around the discovery and distribution of Nutonium products through a single mobile interface. The current product combines account creation, email OTP verification for signup, Google sign-in, role-aware profile routing, a social market feed, a Kerala-focused seller map, inventory browsing, and a multi-seller cart workflow.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("Cloud Firestore is used to store user metadata, seller profiles, and marketplace content, while Firebase Authentication manages account access. A shared marketplace service merges Firestore data with seeded fallback content so that the interface remains demonstrable even when remote records are incomplete. The design system uses a classical palette of forest green, brass, and parchment with a premium card-based layout to position the product as a polished trading application rather than a generic marketplace clone.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("This report documents the implemented features, architecture, data design, testing status, and known limitations of the present codebase. It also identifies the work still required for production readiness, including secure server-side OTP delivery, seller-side post composition, checkout processing, and stronger state-management standardization.", font: serif(13), color: ink, width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 0)
}

func drawContentsPage() {
    builder.beginPage(prelimStyle)
    builder.drawCenteredParagraph("TABLE OF CONTENTS", font: serif(24, bold: true), color: ink, width: 320, top: 84, spacingAfter: 26)
    builder.drawTwoColumnRows(title: "Front Matter", rows: [
        ("Cover Page", "Project title, submission note, and report identity."),
        ("Certificate", "Scope of documentation and submission placeholders."),
        ("Declaration", "Statement of authorship and factual basis."),
        ("Acknowledgement", "Recognition of tools, libraries, and development effort."),
        ("Abstract", "Condensed overview of system purpose and current status."),
    ])
    builder.drawTwoColumnRows(title: "Chapters", rows: [
        ("Chapter 1", "Introduction and project snapshot."),
        ("Chapter 2", "Problem definition and objectives."),
        ("Chapter 3", "Requirement analysis and feasibility."),
        ("Chapter 4", "System architecture and data flow."),
        ("Chapter 5", "Module design and implementation status."),
        ("Chapter 6", "Database design and collection structure."),
        ("Chapter 7", "User interface and experience strategy."),
        ("Chapter 8", "Testing, stabilization, and current status."),
        ("Chapter 9", "Limitations and future enhancements."),
        ("Conclusion", "Overall assessment of the Nutonium build."),
        ("References and Appendix", "Technology references, metrics, and source-map summary."),
    ])
}

func drawChapter1() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "1", title: "Introduction", subtitle: "Why Nutonium exists and what the current application attempts to solve")
    builder.drawParagraph("Small retail and wholesale trade networks often depend on fragmented communication channels. Product availability, promotional offers, event announcements, and seller discovery are commonly split across calls, messaging apps, local knowledge, or manual follow-up. This creates friction for buyers and weakens visibility for sellers who need a structured digital surface.", spacingAfter: 14)
    builder.drawParagraph("Nutonium addresses that gap through a mobile-first marketplace that brings together customer access, retailer visibility, wholesaler supply, and map-based discovery. The application is built with Flutter for cross-platform delivery and Firebase for identity and data persistence. The design target is a premium but practical marketplace interface that feels closer to a curated trade board than a generic e-commerce template.", spacingAfter: 14)
    builder.drawCallout(title: "Project Snapshot", body: "The inspected codebase contains 51 Dart source files and roughly 11,313 lines across core, auth, social, map, cart, profile, and shared modules. The main shell exposes four tabs: market feed, cart, map, and profile.", tint: canvas)
    builder.drawSectionTitle("Primary User Roles")
    builder.drawBulletList([
        "Customer: browses feed content, views mapped sellers, explores shop inventory, adds products to the cart, and manages the personal account view.",
        "Retailer: has a dedicated profile setup model in Firestore and is represented as a seller on the marketplace map and feed.",
        "Wholesaler: maintains business profile data, higher-volume inventory assumptions, and appears on the map and feed as a bulk supply source.",
    ])
}

func drawChapter2() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "2", title: "Problem Definition and Objectives", subtitle: "The business pain points and the measurable goals encoded in the product")
    builder.drawSectionTitle("Problem Statement")
    builder.drawBulletList([
        "Nearby seller discovery is inconsistent when buyers do not know which shops actively carry Nutonium stock.",
        "Retailers and wholesalers lack a shared mobile surface for current offers, events, and stock signals.",
        "Purchase intent is fragmented because users must manually remember which seller offered which product and price.",
        "Onboarding for businesses needs structured profile capture so seller data can be shown consistently on the map and in the marketplace feed.",
        "Trust and conversion suffer when authentication and account recovery are incomplete or error-prone.",
    ])
    builder.drawSectionTitle("Project Objectives")
    builder.drawNumberedList([
        "Provide a single mobile entry point for Nutonium customers and sellers.",
        "Implement dependable authentication using Firebase email/password login, Google sign-in, and signup-time email OTP verification.",
        "Show Nutonium sellers on a Kerala-centered live map with filters for role and stock readiness.",
        "Surface market activity through a social-style board of offers, events, and updates.",
        "Enable a multi-seller cart that behaves like a procurement draft rather than a simple single-shop basket.",
        "Route users through role-specific profile completion and preserve safe recovery when profile documents are missing.",
    ])
}

func drawChapter3() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "3", title: "Requirement Analysis and Feasibility", subtitle: "Functional scope, non-functional expectations, and why the stack is workable")
    builder.drawSectionTitle("Functional Requirements")
    builder.drawBulletList([
        "Email and password sign-in for existing users.",
        "OTP-protected account creation using email delivery before the Firebase account is committed.",
        "Forgot password support via Firebase password reset email.",
        "Role-aware routing so incomplete seller profiles reach the correct setup screens.",
        "Map-based seller discovery with retailer, wholesaler, and ready-stock filters.",
        "Marketplace feed search by title, shop, description, and location.",
        "Inventory browsing per seller and add-to-cart actions with minimum-order handling.",
        "Profile loading, logout, and resilience against missing user profile documents.",
    ])
    builder.drawSectionTitle("Non-Functional Requirements")
    builder.drawBulletList([
        "Responsive interface behavior on mobile form factors using Flutter layouts and SafeArea handling.",
        "Readable classical visual identity rather than default boilerplate styling.",
        "Graceful fallback when remote marketplace data is absent or incomplete.",
        "Reasonable maintainability through feature folders, shared services, and explicit models.",
        "Security suitable for prototyping through Firebase Auth, while recognizing that client-side SMTP OTP delivery is not production-safe.",
    ])
    builder.drawSectionTitle("Feasibility Summary")
    builder.drawParagraph("The chosen stack is technically feasible because Flutter can deliver the full application surface from a single Dart codebase, while Firebase handles identity and data storage without requiring a custom server at prototype stage. Operationally, the marketplace concept is feasible because seller profiles, product offers, and location labels all fit well into Firestore documents and can be displayed in real time. Economically, the approach is efficient for a student or early-stage product team because most infrastructure remains managed and pay-as-you-scale.", spacingAfter: 0)
}

func drawChapter4() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "4", title: "System Architecture and Data Flow", subtitle: "How the Flutter shell, shared services, and cloud services work together")
    builder.drawParagraph("The project uses a layered mobile architecture. The entry point in main.dart initializes Firebase and launches a MaterialApp using the shared theme. AuthWrapper listens to Firebase Authentication state changes, while ProfileChecker queries the users collection to determine whether a signed-in user should move into the main marketplace shell or into a seller profile completion screen.", spacingAfter: 12)
    builder.drawParagraph("MainNavigationScreen provides the persistent application shell. It hosts the market feed, cart, map, and profile screens inside an IndexedStack, with a shared top bar and bottom navigation. The cross-feature bridge is MarketplaceService, which loads seller data, loads feed content, merges seeded content with Firestore data, and owns the ValueNotifier that stores cart state.", spacingAfter: 12)
    builder.drawArchitectureDiagram()
    builder.drawSectionTitle("Runtime Flow")
    builder.drawBulletList([
        "Authentication state is resolved first; no marketplace feature is shown until Firebase reports a user or an unauthenticated state.",
        "ProfileChecker reads the users document and selects the right screen branch based on role and profile completeness.",
        "MarketplaceService reads sellers from retailers and wholesalers collections, then merges those results with seeded showcase shops so the map and feed remain populated.",
        "Social feed cards and shop inventory screens call the cart service layer directly when users add products.",
        "Map actions, top-bar trade-code shortcuts, and inventory pages all converge on the same shared cart state.",
    ])
}

func drawChapter5() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "5", title: "Module Design and Implementation", subtitle: "Implemented modules, current behavior, and modules still partially complete")
    builder.drawTwoColumnRows(title: "Implementation Matrix", rows: [
        ("Authentication", "Implemented: email/password login, Google sign-in for customer flow, signup-time email OTP verification, and password reset email."),
        ("Seller Profile Setup", "Implemented: separate retailer and wholesaler forms with business category and location capture."),
        ("Market Feed", "Implemented for browsing: filters, search, pinned posts, CTA to cart, and CTA to map or inventory."),
        ("Seller Posting", "Service-ready but UI-pending: MarketplaceService can publish posts, but the present UI does not yet expose a seller post composer."),
        ("Map and Inventory", "Implemented: Kerala-centered flutter_map view, marker selection, filter rail, and inventory screen per shop."),
        ("Cart", "Implemented: grouped procurement draft, quantity control, savings summary, and cross-screen add-to-cart integration."),
        ("Camera and Directions", "Partial: camera capture screen exists, but photo publishing and route guidance are not yet connected end-to-end."),
    ])

    builder.drawSectionTitle("Authentication and Recovery")
    builder.drawBulletList([
        "UniversalAuthScreen handles sign-in and routes signup into the OTP verification flow.",
        "OtpVerificationScreen validates the emailed code, creates the Firebase account only after correct OTP entry, and writes the user document with emailOtpVerified metadata.",
        "ForgotPasswordScreen currently uses Firebase's reset-email workflow rather than a custom OTP-based password reset screen.",
        "GoogleAuthScreen creates a customer account path using Google Sign-In and merges the profile into Firestore if it is missing.",
    ])

    builder.drawSectionTitle("Marketplace, Map, and Cart")
    builder.drawBulletList([
        "SocialScreen provides content search, kind-based filtering, pinned-card prioritization, and direct CTA actions into inventory or cart.",
        "MapScreen renders seller markers using flutter_map and OpenStreetMap tiles, with stock-based styling and role-specific filters.",
        "ShopInventoryScreen exposes shop products, minimum-order semantics, and a dedicated add-to-cart path.",
        "CartScreen groups items by seller, normalizes quantities to minimum order, displays summary metrics, and exposes procurement-style actions.",
    ])

    builder.forcePageBreak(bodyStyle)
    builder.drawChapterHeading(number: "5", title: "Module Design and Implementation (Continued)", subtitle: "Profile and shared-service behaviors")
    builder.drawSectionTitle("Profile and Navigation Behaviors")
    builder.drawBulletList([
        "ProfileScreen loads the common users record first, then resolves retailer or wholesaler detail documents when relevant.",
        "Seller setup screens write structured business records to Firestore and then mark the top-level user document as profile-complete.",
        "MainNavigationScreen centralizes top-bar actions such as search launch, trade-code handoff, camera access, and quick menu routing.",
        "MissingUserProfileRecovery protects the product against states where an authenticated user exists in Firebase Auth but the Firestore user document is absent.",
    ])
    builder.drawCallout(title: "Architectural Observation", body: "The repository includes bloc dependencies, but the dominant interaction model in the current snapshot is a combination of StatefulWidget state, ValueNotifier cart state, and shared service orchestration. That is workable for a prototype, but a future refactor could standardize state handling more consistently.", tint: canvas)
}

func drawChapter6() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "6", title: "Database Design", subtitle: "Firestore collections, profile documents, feed content, and fallback strategy")
    builder.drawParagraph("Cloud Firestore is the main persistence layer. The design separates identity-oriented metadata from seller-specific business documents. The users collection contains the primary role flag, display name, email, completeness state, and timestamps. Retailer and wholesaler collections extend that record with business details, categories, and location maps containing address fields and optional latitude/longitude.", spacingAfter: 12)
    builder.drawParagraph("Marketplace content is represented across social_feed and posts documents. This allows a social timeline and a broader post repository to stay aligned while still being read differently by future features. A DatabaseInitializer utility also demonstrates auxiliary collections such as user_posts and post_analytics for future expansion.", spacingAfter: 12)
    builder.drawFirestoreDiagram()
    builder.drawSectionTitle("Data Characteristics")
    builder.drawBulletList([
        "Location data may arrive with missing coordinates; MarketplaceService therefore infers fallback coordinates from city names so sellers can still be shown on the map.",
        "Seeded showcase shops and posts are kept in the service layer to guarantee a demonstrable UI even when remote records are empty.",
        "Cart state is currently in-memory through a ValueNotifier and is not yet persisted to Firestore between sessions.",
        "Retailer and wholesaler profiles include taxation and licensing fields, but payments, invoices, and order histories are not yet modeled as first-class collections.",
    ])
}

func drawChapter7() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "7", title: "User Interface and Experience Strategy", subtitle: "The classical visual direction and its impact on product identity")
    builder.drawParagraph("The Nutonium interface deliberately avoids default marketplace aesthetics. The theme defined in the core app palette uses forest green, brass, parchment, and canvas tones to create a classic trading-desk atmosphere. Cormorant Garamond is used as the display face for elegant headings, while Manrope supports body readability and navigation labels.", spacingAfter: 14)
    builder.drawBulletList([
        "Rounded cards, pill filters, and layered hero panels create a premium but familiar touch target structure.",
        "The top bar acts as an operational console by exposing search, trade-code, camera, and menu actions directly from the market shell.",
        "Map markers and status chips use semantic colors to distinguish high, medium, and low stock without relying only on text.",
        "The cart experience behaves more like a sourcing worksheet than a minimal shopping bag, emphasizing seller grouping and procurement totals.",
        "SafeArea usage, scroll containers, and large touch surfaces help the UI translate between device sizes while staying mobile-first.",
    ])
    builder.drawCallout(title: "Design Consistency Note", body: "Most of the current screens follow the classical green-brass design system. One notable outlier is the camera screen, which still uses an older purple accent and should be aligned to the main visual language in a future cleanup pass.", tint: parchment)
}

func drawChapter8() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "8", title: "Testing, Stabilization, and Current Status", subtitle: "What is currently working, what was debugged, and where the product stands now")
    builder.drawSectionTitle("Stabilization Highlights")
    builder.drawBulletList([
        "Signup flow was reordered so the email OTP step completes before the Firebase account is created, preventing failed-first-attempt duplicate-account states.",
        "Profile timestamp parsing was hardened so null server timestamps do not crash the profile path immediately after account creation.",
        "Logout handling was cleaned up to avoid context-related assertions while the authenticated widget tree is being torn down.",
        "Shared button sizing was corrected so cart recommendation rows do not request infinite width during layout.",
        "The cart screen implementation was restored and analyzed after a class-path mismatch caused a compile-time failure in the main navigation shell.",
    ])
    builder.drawTwoColumnRows(title: "Current Product Status", rows: [
        ("Customer Onboarding", "Working with email/password login, signup OTP verification, Google sign-in, and password reset email."),
        ("Seller Onboarding", "Working for retailer and wholesaler profile setup with category and location capture."),
        ("Marketplace Browsing", "Working for feed discovery, map browsing, inventory views, and cart addition."),
        ("Seller Post Composer", "Not yet exposed in the present UI, although a publish service exists in the shared layer."),
        ("Checkout and Orders", "Not yet implemented as a completed payment or order-placement workflow."),
        ("Mail Delivery Model", "Development-ready only; it depends on runtime SMTP configuration and should be replaced in production."),
    ])
    builder.drawCallout(title: "Verification Snapshot", body: "The repository includes a widget smoke test for the navigation shell. Static analysis was also used during stabilization to validate navigation and cart modules after error correction. This improves confidence, but the project still needs broader automated testing before production deployment.", tint: canvas)
}

func drawChapter9() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "9", title: "Limitations and Future Enhancements", subtitle: "What still needs to change before Nutonium becomes a complete product")
    builder.drawSectionTitle("Current Limitations")
    builder.drawBulletList([
        "Signup OTP delivery currently depends on client-side SMTP configuration, which is not secure for production deployment.",
        "Forgot-password flow uses Firebase reset email rather than the custom email-OTP reset journey originally envisioned.",
        "Seller-side creation of offers and events is prepared at service level but not exposed through a dedicated composition UI.",
        "Directions, checkout, payments, order persistence, and invoice management are not yet implemented end-to-end.",
        "Cart state is not persisted across app restarts, and analytics remain mostly scaffolded rather than surfaced in the interface.",
        "State management is mixed; long-term maintainability would improve with a more standardized approach.",
    ])
    builder.drawSectionTitle("Recommended Next Enhancements")
    builder.drawNumberedList([
        "Move OTP and transactional email sending to a server-side channel such as Firebase Cloud Functions with a secure mail provider.",
        "Implement a seller posting console so retailers and wholesalers can publish offers and events directly from the mobile app.",
        "Add persistent order, checkout, and payment collections to convert the cart from a draft into a real transaction engine.",
        "Capture exact geolocation during seller onboarding and connect the map's directions action to a real routing provider.",
        "Unify state management across the app and increase coverage with integration tests for auth, feed, cart, and profile flows.",
        "Extend the current design system to the remaining outlier screens for full brand consistency.",
    ])
}

func drawConclusionPage() {
    builder.beginPage(bodyStyle)
    builder.drawCenteredParagraph("CONCLUSION", font: serif(24, bold: true), color: ink, width: 240, top: 86, spacingAfter: 22)
    builder.drawParagraph("Nutonium already demonstrates the backbone of a distinctive marketplace product. The codebase supports secure account entry, role-sensitive routing, seller mapping, inventory exploration, social market browsing, and a unified cart flow with a clear visual identity. That combination is strong enough to serve as a serious prototype rather than a superficial UI demo.", font: serif(13), width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawParagraph("At the same time, the report makes clear where the project still needs engineering depth. Production-safe OTP delivery, seller-side publishing, checkout, order persistence, and broader automated testing remain the most important next steps. Even with those gaps, the present implementation establishes a coherent product direction, a workable architecture, and a polished marketplace experience centered on Nutonium trade discovery.", font: serif(13), width: 440, x: 78, alignment: .justified, lineSpacing: 4, spacingAfter: 16)
    builder.drawCallout(title: "Overall Assessment", body: "Nutonium is beyond an empty concept stage. It has a real navigation shell, cloud-backed user flow, mapped seller discovery, inventory drill-down, and a cart orchestration layer. The remaining work is mostly in product completion and infrastructure hardening, not in inventing the product from scratch.", tint: canvas)
}

func drawReferencesAndAppendix() {
    builder.beginPage(bodyStyle)
    builder.drawChapterHeading(number: "10", title: "References and Appendix", subtitle: "Official technologies, project metrics, and codebase summary")
    builder.drawSectionTitle("References")
    builder.drawNumberedList([
        "Flutter Documentation - application framework, widgets, rendering, and testing guidance.",
        "Dart Language Documentation - language features and package ecosystem details.",
        "Firebase Authentication Documentation - email/password auth, account recovery, and federated sign-in workflows.",
        "Cloud Firestore Documentation - document collections, timestamps, and client integration patterns.",
        "flutter_map and OpenStreetMap Documentation - tile-based map rendering and marker configuration.",
        "Google Sign-In for Flutter Documentation - OAuth account selection and token exchange.",
        "Mailer Package Documentation - SMTP-based email delivery used for development-time OTP sending.",
        "Image Picker Package Documentation - camera capture entry point used in the current project.",
    ])
    builder.drawTwoColumnRows(title: "Appendix A: Project Metrics", rows: [
        ("Code Snapshot Date", "5 April 2026"),
        ("Primary Language", "Dart with Flutter UI and Firebase integrations"),
        ("Dart Source Files", "51 files in the lib directory"),
        ("Approximate Source Size", "11,313 lines across the current application code"),
        ("Major Dependencies", "firebase_core, firebase_auth, cloud_firestore, flutter_map, latlong2, google_sign_in, mailer, image_picker, google_fonts"),
        ("Seeded Demo Content", "4 showcase shops and 4 showcase posts used as marketplace fallback content"),
    ])
    builder.drawTwoColumnRows(title: "Appendix B: Key Implementation Files", rows: [
        ("Application Entry", "lib/main.dart initializes Firebase and controls auth-to-profile routing."),
        ("Navigation Shell", "lib/core/presentation/screens/main_navigation_screen.dart hosts the top bar, bottom navigation, and tab stack."),
        ("Shared Marketplace Logic", "lib/shared/services/marketplace_service.dart owns seller loading, feed loading, post publishing service, and cart state."),
        ("Feed and Inventory", "lib/features/social/presentation/screens/social_screen.dart and shop_inventory_screen.dart implement browsing and product drill-down."),
        ("Map Workflow", "lib/features/map/presentation/screens/map_screen.dart renders seller discovery on the Kerala map."),
        ("Auth Workflow", "lib/features/auth/presentation/screens/universal_auth_screen.dart and otp_verification_screen.dart implement signup and login behavior."),
    ])
}

drawCoverPage()
drawCertificatePage()
drawDeclarationPage()
drawAcknowledgementPage()
drawAbstractPage()
drawContentsPage()
drawChapter1()
drawChapter2()
drawChapter3()
drawChapter4()
drawChapter5()
drawChapter6()
drawChapter7()
drawChapter8()
drawChapter9()
drawConclusionPage()
drawReferencesAndAppendix()

let outputPath: String
if CommandLine.arguments.count > 1 {
    outputPath = CommandLine.arguments[1]
} else {
    outputPath = "reports/nutonium_project_report.pdf"
}

let outputURL: URL
if outputPath.hasPrefix("/") {
    outputURL = URL(fileURLWithPath: outputPath)
} else {
    outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(outputPath)
}

try builder.finalize(to: outputURL)
print(outputURL.path)
