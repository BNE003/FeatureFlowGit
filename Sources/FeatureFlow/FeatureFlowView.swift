import SwiftUI

public struct FeatureFlowView: View {
    let appId: String

    @StateObject private var client = SupabaseClient()
    @State private var showSubmitSheet = false

    public init(appId: String) {
        self.appId = appId
    }

    public var body: some View {
        NavigationView {
            FeatureListView(client: client, appId: appId)
                .navigationTitle("Features & Feedback")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showSubmitSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                .sheet(isPresented: $showSubmitSheet) {
                    SubmitFeatureView(client: client, appId: appId)
                }
        }
    }
}

#Preview {
    FeatureFlowView(appId: "demo-app-001")
}
