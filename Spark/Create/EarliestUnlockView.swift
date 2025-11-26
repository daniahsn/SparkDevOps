import SwiftUI

struct EarliestUnlockView: View {

    @EnvironmentObject var storage: StorageService

    let title: String
    let content: String
    let geofence: Geofence?
    let weather: Weather?
    let emotion: Emotion?

    @Binding var path: NavigationPath

    @State private var useDuration = true

    @State private var years: Int = 0
    @State private var months: Int = 0
    @State private var days: Int = 2
    @State private var hours: Int = 0

    @State private var unlockDate: Date = Calendar.current.date(byAdding: .day, value: 2, to: Date())!

    enum WheelType { case years, months, days, hours }
    @State private var wheelType: WheelType? = nil
    @State private var showWheelPicker = false

    var body: some View {
        VStack(spacing: 10) {

            Text("Unlock Time")
                .font(BrandStyle.title)

            Text("Choose when the entry can unlock earliest.")
                .font(BrandStyle.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Mode Switch
            HStack {
                Button { useDuration = true } label: {
                    Text("Time")
                        .font(BrandStyle.button)
                        .foregroundColor(useDuration ? .white : BrandStyle.accent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(useDuration ? BrandStyle.accent : .white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrandStyle.accent))
                }

                Button { useDuration = false } label: {
                    Text("Date")
                        .font(BrandStyle.button)
                        .foregroundColor(!useDuration ? .white : BrandStyle.accent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(!useDuration ? BrandStyle.accent : .white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrandStyle.accent))
                }
            }

            if useDuration { durationSelector } else { dateSelector }

            Spacer()

            Button {
                saveEntry()
                path.append("finish")
            } label: {
                Text("Finish")
                    .font(BrandStyle.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BrandStyle.accent)
                    .cornerRadius(12)
            }
        }
        .padding()
        .overlay {
            if showWheelPicker { wheelDialog }
        }
    }

    // MARK: Duration UI
    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Unlock after:")
                .font(BrandStyle.sectionTitle)

            VStack(spacing: 14) {
                durationRow(label: "Years", value: years) { showWheel(.years) }
                durationRow(label: "Months", value: months) { showWheel(.months) }
                durationRow(label: "Days", value: days) { showWheel(.days) }
                durationRow(label: "Hours", value: hours) { showWheel(.hours) }
            }
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandStyle.accent))
        }
    }

    private func durationRow(label: String, value: Int, onTap: @escaping () -> Void) -> some View {
        HStack {
            Text(label).font(BrandStyle.body)

            Spacer()

            Text("\(value)")
                .font(BrandStyle.body)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 8).stroke(BrandStyle.accent))
                .onTapGesture(perform: onTap)
        }
    }

    // MARK: Date Picker
    private var dateSelector: some View {
        VStack {
            DatePicker(
                "",
                selection: $unlockDate,
                in: Date()...Date.distantFuture,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(BrandStyle.accent)
            .padding(12)
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandStyle.accent))
    }

    // MARK: Wheel Dialog
    private var wheelDialog: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()

            VStack(spacing: 0) {

                Picker("", selection: currentWheelBinding) {
                    ForEach(0..<1001, id: \.self) { v in Text("\(v)").tag(v) }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                Button("Done") {
                    showWheelPicker = false
                }
                .font(BrandStyle.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(BrandStyle.accent)
                .cornerRadius(12)
                .padding(.top, 10)
                .padding(.horizontal, 20)
            }
            .frame(width: 250)
        }
    }

    private var currentWheelBinding: Binding<Int> {
        switch wheelType {
        case .years: return $years
        case .months: return $months
        case .days: return $days
        case .hours: return $hours
        case .none: return .constant(0)
        }
    }

    private func showWheel(_ type: WheelType) {
        wheelType = type
        showWheelPicker = true
    }

    private func saveEntry() {
        let earliestUnlock: Date

        if useDuration {
            let comp = DateComponents(year: years, month: months, day: days, hour: hours)
            earliestUnlock = Calendar.current.date(byAdding: comp, to: Date())!
        } else {
            earliestUnlock = unlockDate
        }

        let entry = SparkEntry(
            title: title,
            content: content,
            geofence: geofence,
            weather: weather,
            emotion: emotion,
            creationDate: Date(),
            earliestUnlock: earliestUnlock,
            unlockedAt: nil
        )

        storage.add(entry)
    }
}

#Preview {
    NavigationStack {
        EarliestUnlockView(
            title: "Sample Title",
            content: "Sample content for preview",
            geofence: nil,
            weather: nil,
            emotion: nil,
            path: .constant(NavigationPath())
        )
        .environmentObject(StorageService.shared)
    }
}
