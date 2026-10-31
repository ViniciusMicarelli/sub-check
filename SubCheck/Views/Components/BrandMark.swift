//
//  BrandMark.swift
//  SubCheck
//
//  Marca do app desenhada em SwiftUI: um ciclo de cobrança (anel com seta)
//  envolvendo um check. Espelha o ícone do app e serve de selo no paywall,
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
                let radius = 285 * unit
                let tint = filled ? Color.white : Color.brand

                // Anel de ciclo: 70° a 370° (anti-horário), montado ponto a
                // ponto para não depender do sentido de `addArc` no Canvas.
                func point(_ degrees: Double, _ r: CGFloat) -> CGPoint {
                    let radians = Angle.degrees(degrees).radians
                    return CGPoint(x: center.x + r * cos(radians), y: center.y - r * sin(radians))
                }
                let ringPoints = stride(from: 70.0, through: 370.0, by: 3.0).map { point($0, radius) }
                var ring = Path()
                ring.addLines(ringPoints)
                context.stroke(
                    ring, with: .color(tint),
                    style: StrokeStyle(lineWidth: 74 * unit, lineCap: .round, lineJoin: .round)
                )

                // Ponta da seta, tangente ao fim do anel (370° = 10°).
                let end = Angle.degrees(370).radians
                let tip = point(370, radius)
                let tangent = CGPoint(x: -sin(end), y: -cos(end))
                let radial = CGPoint(x: cos(end), y: -sin(end))
                var head = Path()
                head.move(to: CGPoint(x: tip.x + tangent.x * 105 * unit, y: tip.y + tangent.y * 105 * unit))
                head.addLine(to: CGPoint(x: tip.x + radial.x * 85 * unit, y: tip.y + radial.y * 85 * unit))
                head.addLine(to: CGPoint(x: tip.x - radial.x * 85 * unit, y: tip.y - radial.y * 85 * unit))
                head.closeSubpath()
                context.fill(head, with: .color(tint))

                // Check.
                var check = Path()
                check.move(to: CGPoint(x: 395 * unit, y: 504 * unit))
                check.addLine(to: CGPoint(x: 480 * unit, y: 592 * unit))
                check.addLine(to: CGPoint(x: 640 * unit, y: 416 * unit))
                context.stroke(
                    check, with: .color(tint),
                    style: StrokeStyle(lineWidth: 86 * unit, lineCap: .round, lineJoin: .round)
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
