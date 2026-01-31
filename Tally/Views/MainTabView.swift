import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var qualificationVM: QualificationViewModel?
    @State private var selectedTab: Int = 0
    
    var body: some View {
        Group {
            if let qualificationVM {
                if qualificationVM.qualifications.isEmpty {
                    noQualificationView
                } else {
                    tabView(qualificationVM: qualificationVM)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if qualificationVM == nil {
                qualificationVM = QualificationViewModel(modelContext: modelContext)
            }
        }
    }
    
    private func tabView(qualificationVM: QualificationViewModel) -> some View {
        TabView(selection: $selectedTab) {
            HomeView(qualificationVM: qualificationVM)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)
            
            MemoListView(qualificationVM: qualificationVM)
                .tabItem {
                    Label("メモ", systemImage: "note.text")
                }
                .tag(1)
            
            SettingsView(qualificationVM: qualificationVM)
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
    
    private var noQualificationView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "graduationcap")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("資格を登録して\n学習を始めましょう")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                NavigationLink {
                    QualificationEditView { name, examDate, weeklyTarget, quotaMode in
                        qualificationVM?.addQualification(name: name, examDate: examDate, weeklyTargetDays: weeklyTarget, quotaMode: quotaMode)
                    }
                } label: {
                    Text("資格を追加")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                Spacer()
            }
        }
    }
}
