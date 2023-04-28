//
//  AnimatedBolt.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-28.
//

import SwiftUI

struct AnimatedBolt: View {
    let batteryPercentage: Double
    @State private var charging: Bool = true
    @State private var animating: Bool = false
    @State private var amplitude: CGFloat = 0.25
    @State private var frequency: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    Spacer()
                    WaveShape(percent: batteryPercentage, amplitude: amplitude, frequency: frequency)
                        .fill(Color.green)
                        .border(.white.opacity(0.5))
                        .frame(height: CGFloat(batteryPercentage / 100) * geometry.size.height)
                        .shadow(color: .green, radius: 12)
                }
                .mask {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .scaledToFit()
                }.shadow(color: .green, radius: 8)
                .background(
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.1)
                )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    amplitude = animating ? 0.25 : 0.4
                    frequency = animating ? 1 : 1.25
                    animating.toggle()
                }
            }
        }
    }
}

struct WaveShape: Shape, Animatable {
    var percent: Double
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(amplitude, frequency) }
        set {
            amplitude = newValue.first
            frequency = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight = amplitude * rect.height
        let startPoint = CGPoint(x: 0, y: rect.height - waveHeight * CGFloat(percent / 100))

        path.move(to: startPoint)
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * frequency * .pi * 2)
            let y = waveHeight * CGFloat(1 - percent / 100) + waveHeight * CGFloat(sine) / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct AnimatedBolt_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedBolt(batteryPercentage: 52.2)
    }
}
