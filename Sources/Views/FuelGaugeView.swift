import SwiftUI

struct FuelGaugeView: View {
    struct Segment { let from: Float; let to: Float; let color: Color }

    var minValue: Float
    var maxValue: Float
    var value: Float
    var unitLabel: String
    var segments: [Segment]

    private var startAngle: Angle { .degrees(135) }
    private var sweepAngle: Angle { .degrees(270) }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 24
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                // Segments
                ForEach(0..<segments.count, id: \.self) { i in
                    let seg = segments[i]
                    ArcShape(startAngle: angle(for: seg.from), endAngle: angle(for: seg.to))
                        .stroke(seg.color, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                // Ticks and labels
                TicksView(min: minValue, max: maxValue, step: majorStep, radius: radius, center: center, startAngle: startAngle, sweepAngle: sweepAngle)

                // Needle
                NeedleView(angle: angle(for: value), radius: radius - 18)
                    .stroke(.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                Circle()
                    .fill(.primary)
                    .frame(width: 10, height: 10)
                    .position(center)

                VStack(spacing: 6) {
                    Text(String(format: "%.2f", value)).font(.system(size: 28, weight: .bold))
                    Text(unitLabel).font(.footnote).foregroundStyle(.secondary)
                }
                .position(x: center.x, y: center.y + radius / 2)
            }
        }
    }

    private var majorStep: Float {
        let range = maxValue - minValue
        switch range {
        case ..<5: return 0.5
        case ..<20: return 1
        case ..<60: return 5
        default: return 10
        }
    }

    private func angle(for v: Float) -> Angle {
        let clamped = max(min(v, maxValue), minValue)
        let ratio = (clamped - minValue) / (maxValue - minValue)
        return startAngle + .degrees(Double(ratio) * sweepAngle.degrees)
    }
}

private struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(center: center, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return p
    }
}

private struct NeedleView: Shape {
    var angle: Angle
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let a = CGFloat(angle.radians)
        let end = CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
        p.move(to: center)
        p.addLine(to: end)
        return p
    }
}

private struct TicksView: View {
    let min: Float
    let max: Float
    let step: Float
    let radius: CGFloat
    let center: CGPoint
    let startAngle: Angle
    let sweepAngle: Angle

    var body: some View {
        Canvas { ctx, size in
            let ticksCount = Int(((max - min) / step).rounded())
            for i in 0...ticksCount {
                let v = min + Float(i) * step
                let a = startAngle + .degrees(Double((v - min) / (max - min)) * sweepAngle.degrees)
                let rad = CGFloat(a.radians)
                let outer = CGPoint(x: center.x + (radius + 2) * cos(rad), y: center.y + (radius + 2) * sin(rad))
                let inner = CGPoint(x: center.x + (radius - 12) * cos(rad), y: center.y + (radius - 12) * sin(rad))
                var p = Path()
                p.move(to: outer)
                p.addLine(to: inner)
                ctx.stroke(p, with: .color(.secondary), lineWidth: 1)

                // Label
                let labelPoint = CGPoint(x: center.x + (radius - 22) * cos(rad), y: center.y + (radius - 22) * sin(rad))
                let text = Text(abs(v - round(v)) < 0.001 ? String(format: "%.0f", v) : String(format: "%.1f", v))
                ctx.draw(text.font(.caption2).foregroundStyle(.secondary), at: labelPoint)
            }
        }
    }
}

#Preview {
    FuelGaugeView(
        minValue: 0, maxValue: 10, value: 3.5, unitLabel: "lt/100km",
        segments: [
            .init(from: 0, to: 3.5, color: .green),
            .init(from: 3.5, to: 7, color: .yellow),
            .init(from: 7, to: 10, color: .red)
        ]
    )
    .frame(height: 240)
    .padding()
}
