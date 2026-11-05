//
//  BrandMark.swift
//  SubCheck
//
//  Marca do app desenhada em SwiftUI: um ciclo de cobrança (anel menta com
//  seta) envolvendo um disco com check. Geometria idêntica a `tools/make-icon.swift`. Espelha o ícone do app e serve de selo no paywall,
//  no vazio das listas e nos cabeçalhos.
//

import SwiftUI

struct BrandMark: View {

    var size: CGFloat = 72
    /// `true` desenha o selo com o fundo em gradiente; `false` só o glifo.
    var filled = true

    var body: some View {
        ZStack {
            if filled {
                RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                    .fill(Color.brandGradient)
                    .shadow(color: Color.brand.opacity(0.35), radius: size * 0.18, y: size * 0.08)
            }

            Canvas { context, canvasSize in
                let unit = canvasSize.width / 1024
                let center = CGPoint(x: 512 * unit, y: 512 * unit)
                let radius = 318 * unit
                let ringColor = Color.brandMint
                let discColor: Color = filled ? .white : Color.brand.opacity(0.14)
                let checkColor: Color = .brand

                // Math coords (y para cima) convertidas para a tela.
                func point(_ degrees: Double, _ r: CGFloat) -> CGPoint {
                    let radians = Angle.degrees(degrees).radians
                    return CGPoint(x: center.x + r * cos(radians), y: center.y - r * sin(radians))
                }

                // Anel de ciclo: 300° no sentido horário (75° até -225°).
                var ring = Path()
                ring.addLines(stride(from: 75.0, through: -225.0, by: -3.0).map { point($0, radius) })
                context.stroke(
                    ring, with: .color(ringColor),
                    style: StrokeStyle(lineWidth: 92 * unit, lineCap: .round, lineJoin: .round)
                )

                // Ponta da seta em 135°, apontando no sentido horário.
                let end = Angle.degrees(135).radians
                let tip = point(135, radius)
                let tangent = CGPoint(x: sin(end), y: cos(end))      // horário, na tela
                let radial = CGPoint(x: cos(end), y: -sin(end))
                var head = Path()
                head.move(to: CGPoint(x: tip.x + tangent.x * 118 * unit, y: tip.y + tangent.y * 118 * unit))
                head.addLine(to: CGPoint(x: tip.x + radial.x * 98 * unit - tangent.x * 6 * unit,
                                         y: tip.y + radial.y * 98 * unit - tangent.y * 6 * unit))
                head.addLine(to: CGPoint(x: tip.x - radial.x * 98 * unit - tangent.x * 6 * unit,
                                         y: tip.y - radial.y * 98 * unit - tangent.y * 6 * unit))
                head.closeSubpath()
                context.fill(head, with: .color(ringColor))
                context.stroke(head, with: .color(ringColor),
                               style: StrokeStyle(lineWidth: 34 * unit, lineJoin: .round))

                // Disco central.
                let disc = CGRect(x: center.x - 214 * unit, y: center.y - 214 * unit,
                                  width: 428 * unit, height: 428 * unit)
                context.fill(Path(ellipseIn: disc), with: .color(discColor))

                // Check.
                var check = Path()
                check.move(to: CGPoint(x: 420 * unit, y: 519 * unit))
                check.addLine(to: CGPoint(x: 492 * unit, y: 592 * unit))
                check.addLine(to: CGPoint(x: 612 * unit, y: 434 * unit))
                context.stroke(
                    check, with: .color(checkColor),
                    style: StrokeStyle(lineWidth: 74 * unit, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        BrandMark(size: 96)
        BrandMark(size: 48, filled: false)
    }
    .padding()
}
