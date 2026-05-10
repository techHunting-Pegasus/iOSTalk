import SwiftUI

struct MovieSearchView: View {
    @StateObject private var vm = EmbedCheckerViewModel()
    @State private var tmdbID: String = "1582770"
    @State private var showPlayer: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("TMDB Movie ID")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        TextField("e.g. 1582770", text: $tmdbID)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .font(.system(.body, design: .monospaced))

                        Button {
                            Task { await vm.checkAll(tmdbID: tmdbID) }
                        } label: {
                            if vm.isChecking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 80)
                                    .padding(.vertical, 12)
                                    .background(Color.indigo)
                                    .cornerRadius(10)
                            } else {
                                Text("Check")
                                    .fontWeight(.semibold)
                                    .frame(width: 80)
                                    .padding(.vertical, 12)
                                    .background(Color.indigo)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(vm.isChecking || tmdbID.isEmpty)
                    }
                }

                // MARK: Providers List
                if vm.providers.contains(where: { $0.status != .idle }) {
                    VStack(spacing: 10) {
                        ForEach(vm.providers.indices, id: \.self) { i in
                            ProviderRow(
                                provider: vm.providers[i],
                                onLoad: {
                                    vm.loadProvider(at: i)
                                    showPlayer = true
                                }
                            )
                        }
                    }
                }

                // MARK: No result warning
                if vm.noneFound {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No working provider found for this ID.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }

                // MARK: Open Player Button
                if let url = vm.activeURL {
                    Button {
                        showPlayer = true
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Play Movie")
                                    .fontWeight(.semibold)
                                Text("via \(vm.activeProviderName)")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .opacity(0.6)
                        }
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showPlayer) {
                        PlayerView(url: url, providerName: vm.activeProviderName)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .alert("No providers found", isPresented: $vm.noneFound) {
            Button("OK", role: .cancel) { vm.noneFound = false }
        } message: {
            Text("All providers failed for TMDB ID \(tmdbID). Try a different ID.")
        }
    }
}
