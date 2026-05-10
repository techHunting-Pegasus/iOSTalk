import SwiftUI

struct ProviderRow: View {
    let provider: EmbedProvider
    let onLoad: () -> Void

    var body: some View {
        HStack(spacing: 14) {

            // Status dot
            ZStack {
                Circle()
                    .fill(dotColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
                    .opacity(provider.status == .checking ? 1 : 1)
                    .scaleEffect(provider.status == .checking ? 1.2 : 1)
                    .animation(
                        provider.status == .checking
                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                            : .default,
                        value: provider.status == .checking
                    )
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(provider.status == .success ? .primary : .secondary)
                Text(provider.status.label)
                    .font(.caption)
                    .foregroundColor(dotColor)
            }

            Spacer()

            // Load button (only on success)
            if provider.status == .success {
                Button(action: onLoad) {
                    Text("Load Player")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(rowBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: provider.status.label)
    }

    private var dotColor: Color {
        switch provider.status {
        case .idle:     return Color(.systemGray3)
        case .checking: return .orange
        case .success:  return .green
        case .failed:   return .red
        }
    }

    private var rowBackground: Color {
        switch provider.status {
        case .success: return Color.green.opacity(0.05)
        case .failed:  return Color(.systemGray6).opacity(0.5)
        default:       return Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        switch provider.status {
        case .success: return Color.green.opacity(0.3)
        case .failed:  return Color(.systemGray4).opacity(0.3)
        default:       return Color.clear
        }
    }
}
