import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StudyViewModel?
    @State private var showAddMaterial = false
    @State private var editingMaterial: Material?
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    if viewModel.materials.isEmpty {
                        emptyStateView
                    } else {
                        mainContentView(viewModel: viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Tally")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMaterial = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMaterial) {
                MaterialEditView(material: nil) { name, total, unit, quota in
                    viewModel?.addMaterial(name: name, totalAmount: total, unit: unit, dailyQuota: quota)
                }
            }
            .sheet(item: $editingMaterial) { material in
                MaterialEditView(material: material) { name, total, unit, quota in
                    viewModel?.updateMaterial(material, name: name, totalAmount: total, unit: unit, dailyQuota: quota)
                }
            }
            .sheet(isPresented: $showSettings) {
                if let viewModel {
                    SettingsView(
                        appSettings: viewModel.appSettings,
                        onUpdateExamDate: { viewModel.updateExamDate($0) },
                        onUpdateWeeklyTarget: { viewModel.updateWeeklyTargetDays($0) },
                        onUpdateQuotaMode: { viewModel.updateQuotaCalculationMode($0) }
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StudyViewModel(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("教材を追加して\n学習を始めましょう")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("教材を追加") {
                showAddMaterial = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Main Content
    
    private func mainContentView(viewModel: StudyViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // 試験日カウントダウン
                CountdownView(
                    daysUntilExam: viewModel.daysUntilExam,
                    onSetExamDate: { showSettings = true }
                )
                
                // 今日のノルマ
                DailyQuotaView(
                    quotas: viewModel.materials.map { material in
                        let quota = viewModel.calculatedDailyQuota(for: material)
                        return (name: material.name, amount: quota, unit: material.unit)
                    }
                )
                
                // 教材ごとの進捗バー
                VStack(spacing: 16) {
                    ForEach(viewModel.materials, id: \.id) { material in
                        MaterialProgressView(material: material) { amount in
                            viewModel.recordProgress(material: material, amount: amount)
                        }
                        .contextMenu {
                            Button {
                                editingMaterial = material
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.deleteMaterial(material)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                // ストリーク & 今週の進捗
                StreakView(
                    streak: viewModel.currentStreak,
                    weeklyStudyDays: viewModel.weeklyStudyDays,
                    weeklyTargetDays: viewModel.appSettings?.weeklyTargetDays ?? 4
                )
                
                // ヒートマップ
                HeatmapView(data: viewModel.heatmapData())
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
