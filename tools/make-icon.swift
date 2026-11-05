// Gera os três ícones (claro, escuro, tinted) de 1024x1024.
// Uso: swiftc tools/make-icon.swift -o /tmp/make-icon && /tmp/make-icon <pasta de saída>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024
let space = CGColorSpaceCreateDeviceRGB()

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [
        CGFloat((hex >> 16) & 255) / 255, CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, a])!
}

func gradient(_ colors: [UInt32]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors.map { rgb($0) } as CFArray, locations: nil)!
}

struct Palette {
    var bg: [UInt32]
    var glow: CGColor
    var ring: [UInt32]
    var disc: [UInt32]
    var check: [UInt32]
}

func point(_ degrees: CGFloat, _ r: CGFloat, _ c: CGPoint) -> CGPoint {
    let a = degrees * .pi / 180
    return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
}

func render(_ p: Palette, to url: URL) {
    let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let c = CGPoint(x: S / 2, y: S / 2)

    // Fundo
    ctx.drawLinearGradient(gradient(p.bg), start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])
    ctx.drawRadialGradient(
        CGGradient(colorsSpace: space, colors: [p.glow, rgb(0xFFFFFF, 0)] as CFArray, locations: nil)!,
        startCenter: CGPoint(x: 330, y: 800), startRadius: 0,
        endCenter: CGPoint(x: 330, y: 800), endRadius: 760, options: [])

    // Anel de ciclo (300°, sentido horário, termina em 135° com a seta)
    let R: CGFloat = 318, width: CGFloat = 92
    let start: CGFloat = 75, end: CGFloat = 135 - 360   // 75° -> -225°
    let ringPath = CGMutablePath()
    ringPath.addArc(center: c, radius: R, startAngle: start * .pi / 180, endAngle: end * .pi / 180, clockwise: true)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34, color: rgb(0x000000, 0.28))
    ctx.addPath(ringPath)
    ctx.setLineWidth(width); ctx.setLineCap(.round)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(gradient(p.ring), start: CGPoint(x: 140, y: 880), end: CGPoint(x: 880, y: 140), options: [])
    ctx.restoreGState()

    // Ponta da seta
    let endAngle: CGFloat = 135
    let tip = point(endAngle, R, c)
    let rad = endAngle * .pi / 180
    let tangent = CGPoint(x: sin(rad), y: -cos(rad))   // sentido horário
    let radial = CGPoint(x: cos(rad), y: sin(rad))
    let head = CGMutablePath()
    head.move(to: CGPoint(x: tip.x + tangent.x * 118, y: tip.y + tangent.y * 118))
    head.addLine(to: CGPoint(x: tip.x + radial.x * 98 - tangent.x * 6, y: tip.y + radial.y * 98 - tangent.y * 6))
    head.addLine(to: CGPoint(x: tip.x - radial.x * 98 - tangent.x * 6, y: tip.y - radial.y * 98 - tangent.y * 6))
    head.closeSubpath()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34, color: rgb(0x000000, 0.28))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.setFillColor(rgb(p.ring[0])); ctx.setStrokeColor(rgb(p.ring[0]))
    ctx.setLineWidth(34); ctx.setLineJoin(.round)
    ctx.addPath(head)
    ctx.drawPath(using: .fillStroke)
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    // Disco central
    let discR: CGFloat = 214
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 46, color: rgb(0x000000, 0.34))
    ctx.addEllipse(in: CGRect(x: c.x - discR, y: c.y - discR, width: discR * 2, height: discR * 2))
    ctx.clip()
    ctx.drawLinearGradient(gradient(p.disc), start: CGPoint(x: c.x, y: c.y + discR), end: CGPoint(x: c.x, y: c.y - discR), options: [])
    ctx.restoreGState()

    // Check
    let check = CGMutablePath()
    check.move(to: CGPoint(x: 420, y: 505))
    check.addLine(to: CGPoint(x: 492, y: 432))
    check.addLine(to: CGPoint(x: 612, y: 590))
    ctx.saveGState()
    ctx.addPath(check)
    ctx.setLineWidth(74); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(gradient(p.check), start: CGPoint(x: 400, y: 600), end: CGPoint(x: 640, y: 420), options: [])
    ctx.restoreGState()

    let image = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")

render(Palette(bg: [0x3B33C9, 0x6B3FE0, 0xA24CF0], glow: rgb(0xFFFFFF, 0.30),
               ring: [0x7CF7C4, 0x22C990], disc: [0xFFFFFF, 0xE6E1FF], check: [0x4F46E5, 0x8B3FE8]),
       to: out.appendingPathComponent("AppIcon.png"))

render(Palette(bg: [0x15112F, 0x241552, 0x3A1C73], glow: rgb(0x8A87FF, 0.28),
               ring: [0x6EF0BA, 0x1FBF88], disc: [0xEDEAFF, 0xC9C2F5], check: [0x3B33C9, 0x6B3FE0]),
       to: out.appendingPathComponent("AppIcon-Dark.png"))

render(Palette(bg: [0x1A1A1A, 0x0C0C0C, 0x000000], glow: rgb(0xFFFFFF, 0.10),
               ring: [0xFFFFFF, 0xBDBDBD], disc: [0xF2F2F2, 0xD0D0D0], check: [0x303030, 0x101010]),
       to: out.appendingPathComponent("AppIcon-Tinted.png"))
