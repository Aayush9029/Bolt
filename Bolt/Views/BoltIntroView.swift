//
//  BoltIntroView.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-03-28.
//

import SwiftUI

struct BoltIntroView: View {
    @State private var animationComplete: Bool = false
    @State private var animate: Bool = false
    @State private var hovering: Bool = false
    @State private var nextView: Bool = false

    var body: some View {
        Group {
            if nextView {
                Text("YO")
            } else {
                VStack {
                    ZStack {
                        AnimatedBolt(batteryPercentage: animate ? 100 : 0)
                        Text(animationComplete ? "NEXT" : "BOLT")
                            .font(.largeTitle.bold())
                            .opacity(animate ? 1 : 0)
                    }
                    .onHover { state in
                        if animationComplete {
                            withAnimation {
                                hovering = state
                            }
                        }
                    }
                }
                .shadow(color: .green, radius: 128)
                .shadow(color: .teal, radius: hovering ? 128 : 0)
                .padding()
                .onAppear {
                    withAnimation(.easeIn(duration: 6)) {
                        animate.toggle()
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 6.0
                    ) {
                        animationComplete.toggle()
                    }
                }
                .onTapGesture {
                    if animationComplete { nextView.toggle() }
                }
            }
        }
    }
}

struct BoltIntroView_Previews: PreviewProvider {
    static var previews: some View {
        BoltIntroView()
    }
}
