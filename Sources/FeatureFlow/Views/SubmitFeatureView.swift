import SwiftUI

struct SubmitFeatureView: View {
    @ObservedObject var client: SupabaseClient
    let appId: String
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Feature-Titel", text: $title)
                        .font(.headline)
                } header: {
                    Text("Titel")
                } footer: {
                    Text("Gib deinem Feature einen klaren und prägnanten Titel")
                        .font(.caption)
                }

                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 150)
                } header: {
                    Text("Beschreibung")
                } footer: {
                    Text("Beschreibe deine Idee so detailliert wie möglich")
                        .font(.caption)
                }

                Section {
                    Button(action: submitFeature) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Feature einreichen")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .navigationTitle("Neues Feature")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .alert("Erfolgreich eingereicht!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Dein Feature wurde erfolgreich eingereicht. Andere Nutzer können nun dafür voten!")
            }
        }
    }

    private func submitFeature() {
        isSubmitting = true

        Task {
            let success = await client.submitFeature(
                appId: appId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces)
            )

            await MainActor.run {
                isSubmitting = false

                if success {
                    showSuccessAlert = true
                }
            }
        }
    }
}
