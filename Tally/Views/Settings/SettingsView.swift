import SwiftUI

struct SettingsView: View {
    let qualificationVM: QualificationViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        QualificationManagementView(qualificationVM: qualificationVM)
                    } label: {
                        HStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundStyle(Theme.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("資格管理")
                                if let name = qualificationVM.selectedQualification?.name {
                                    Text(name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("2.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}
