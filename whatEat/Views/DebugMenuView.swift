import SwiftUI
#if DEBUG
import PulseUI
#endif

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
#if DEBUG
                NavigationLink("Pulse") {
                    PulseConsoleView()
                }
#endif
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

#if DEBUG
private struct PulseConsoleView: View {
    var body: some View {
        ConsoleView()
            .navigationTitle("Pulse")
    }
}
#endif
