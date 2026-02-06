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

    @State private var isPresented: Bool = false
    @State private var showDetails: Bool = true

    var body: some View {
        @Bindable var vm = boltVM

        MacControlCenterMenu(isPresented: $isPresented) {
            // MARK: - Helper Status
            if !boltVM.isHelperRunning {
                MenuSection("Helper Required", divider: false)
                MenuCommand("Install Helper Daemon") {
                    boltVM.installHelper()
                }
                Text("The privileged helper is needed to control charging.\nApprove it in System Settings → Login Items.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                Divider()
            }

            // MARK: - Charge Limit Slider
            MenuSection("Charge Limit", divider: false)
            MenuSlider(
                value: Binding(
                    get: { CGFloat(boltVM.bclmValue) / 100.0 },
                    set: { vm.bclmValue = max(20, min(100, Int($0 * 100))) }
                ),
                image: Image(systemName: boltVM.bclmValue >= 100 ? "battery.100.bolt" : "battery.75")
            )

            // MARK: - Current Info
            MenuSection("Status")
            HStack {
                Text("Charge Limit")
                    .foregroundStyle(.secondary)
                Spacer()
                if boltVM.bclmValue < 100 {
                    Text("\(boltVM.bclmValue)%")
                        .foregroundStyle(.primary)
                } else {
                    Text("Disabled")
                        .foregroundStyle(.tertiary)
                }
            }

            if let info = boltVM.batteryInfo {
                HStack {
                    Text("Battery")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(info.currentCapacity ?? 0)%")
                        .foregroundStyle(.primary)
                }

                HStack {
                    Text("Charging")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if boltVM.chargingInhibited {
                        Text("Inhibited")
                            .foregroundStyle(.orange)
                    } else if info.isCharging == true {
                        Text("Active")
                            .foregroundStyle(.green)
                    } else {
                        Text("Not Charging")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Power Source")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(info.powerSourceState ?? "Unknown")
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

            // MARK: - Battery Details
            if showDetails {
                MenuSection("Battery Details")
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

            MenuCommand("Quit Bolt") {
                // Reset charging to normal before quitting
                ServiceManager.instance.setResetValues()
                NSApp.terminate(nil)
            }
        }
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
            .environment(BoltViewModel())
    }
}
