//
//  MenuView.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-28.
//

import MacControlCenterUI
import SwiftUI

struct MenuView: View {
    @Environment(BoltViewModel.self) var boltVM

//    if option key was help show it
    @State private var silderValue: CGFloat = 0.45
    @State private var showDetails: Bool = true
    @State private var isPresented: Bool = false

    var body: some View {
        MacControlCenterMenu(isPresented: $isPresented) {
            MenuSection("Limit Charging", divider: false)
            MenuSlider(
                value: $silderValue,
                image: Image(systemName: silderValue > 95 ? "battery.100.bolt" : "battery.75")
            )
            .onChange(of: silderValue) { _, newValue in
                boltVM.updateBCLM(newValue: Int(newValue * 100))
            }

            MenuSection("Current Information")
            HStack {
                Text("Charge Limit")
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if boltVM.bclmValue < 95 {
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
            if showDetails {
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
            }
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

    func isOptionkeyPressed() -> Bool {
        return NSApp.currentEvent?.modifierFlags.contains(.option) == true
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
            .frame(width: 320)
            .padding(.vertical)
            .environment(BoltViewModel())
    }
}
