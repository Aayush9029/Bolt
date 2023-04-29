//
//  MenuView.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-28.
//

import MacControlCenterUI
import Sparkle
import SwiftUI

struct MenuView: View {
//    updateBCLMValue
    @Binding var isPresented: Bool
    @EnvironmentObject var boltVM: BoltViewModel
    var updater: SPUUpdater? = nil
    var body: some View {
        MacControlCenterMenu(isPresented: $isPresented) {
            MenuSection("Limit Charging", divider: false)
            MenuSlider(
                value: $boltVM.limitCharge,
                image: Image(systemName: boltVM.bclmValue > 95 ? "battery.100.bolt" : "battery.75")
            )

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
            if let info = boltVM.batteryInfo {
                HStack {
                    Text("Current Capacity")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(info.currentCapacity ?? 0)%")
                        .foregroundStyle(.primary)
                }
                if let time = info.timeToEmptyFormatted() {
                    HStack {
                        Text("Time Till Empty")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(time)
                            .foregroundStyle(.primary)
                    }
                }
            }

            MenuSection("Battery Information")
            VStack(spacing: 6) {
                if let info = boltVM.batteryInfo {
                    ForEach(info.properties, id: \.key) { item in
                        if !item.value.isEmpty {
                            HStack {
                                Text(item.key)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.value)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            Divider()

            if let updater {
                CheckForUpdates(updater: updater)
            }

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
        MenuView(isPresented: .constant(true))
            .frame(width: 320)
            .padding(.vertical)
            .environmentObject(BoltViewModel())
    }
}
