//
//  MenuView.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-28.
//

import MacControlCenterUI
import SwiftUI

struct MenuView: View {
    @EnvironmentObject var boltVM: BoltViewModel
    var body: some View {
        MacControlCenterMenu(isPresented: .constant(true)) {
            MenuSection("Limit Charging", divider: false)
            MenuSlider(value: $boltVM.limitCharge, image: Image(systemName: boltVM.bclmValue > 95 ? "battery.100.bolt" : "battery.75"))

            MenuSection("Current Information")
            HStack {
                Text("Charge Limit")
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if boltVM.limitCharge < 0.95 {
                        Text(String(boltVM.bclmValue) + "%")
                            .foregroundStyle(.primary)
                    } else {
                        Text("Disabled")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            HStack {
                Text("Current Percentage")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(boltVM.getCurrentBattery() ?? 0) + "%")
                    .foregroundStyle(.primary)
            }
//            HStack {
//                Text("Power Source")
//                    .foregroundStyle(.secondary)
//                Spacer()
//                Text("Power Adapter")
//                    .foregroundStyle(.primary)
//            }

//            MenuSection("Battery Health")
//            HStack {
//                Text("Condition")
//                    .foregroundStyle(.secondary)
//                Spacer()
//                Text("Normal")
//                    .foregroundStyle(.primary)
//            }
//
//            HStack {
//                Text("Max Capacity")
//                    .foregroundStyle(.secondary)
//                Spacer()
//                Text("98%")
//                    .foregroundStyle(.primary)
//            }

            Divider()

            MenuCommand("About Bolt...") {
                showStandardAboutWindow()
            }
        }
    }

    // View Example
    @ViewBuilder
    private func MaxChargeSlider() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Label(boltVM.bclmValue > 95 ? "Full Charge" : "Charge Limit", systemImage: boltVM.bclmValue > 95 ? "battery.100.bolt" : "battery.75")
                Spacer()
                Text("\(boltVM.bclmValue)%")
                    .foregroundStyle(.secondary)
            }

            MenuSlider(value: .constant(0.50), image: Image(systemName: "bolt.fill"))
        }
        .ccGlassButton()
    }

    func showStandardAboutWindow() {
        NSApp.sendAction(
            #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            to: nil,
            from: nil
        )
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
            .frame(width: 320)
            .padding(.vertical)
            .environmentObject(BoltViewModel())
    }
}
