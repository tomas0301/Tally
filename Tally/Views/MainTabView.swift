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
        }
        .tint(Theme.primary)
        .tint(Theme.primary)
    }
    
    private var noQualificationView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.primaryGradient)
                    .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("ようこそ Tallyへ")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("資格を登録して\n学習を始めましょう")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                NavigationLink {
                    QualificationEditView { name, examDate, weeklyTarget, quotaMode in
                        qualificationVM?.addQualification(name: name, examDate: examDate, weeklyTargetDays: weeklyTarget, quotaMode: quotaMode)
                    }
                } label: {
                    Text("資格を追加")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.buttonHeight)
                        .background(Theme.primaryGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        .shadow(color: Theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                Spacer()
            }
            .background(Theme.background)
        }
    }
}
