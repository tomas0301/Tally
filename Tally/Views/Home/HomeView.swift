import SwiftUI
import SwiftData

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    let qualificationVM: QualificationViewModel
    @State private var viewModel: HomeViewModel?
    @State private var showAddMaterial = false
    @State private var editingMaterial: Material?
    @State private var showCalendar = false
    @State private var selectedDate: Date?
    
    private var qualification: Qualification? {
        qualificationVM.selectedQualification
    }
    
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
            .navigationTitle(qualification?.name ?? "Tally")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMaterial = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(qualification == nil)
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
            .sheet(isPresented: $showCalendar) {
                if let viewModel {
                    StudyCalendarView(heatmapData: viewModel.heatmapData()) { date in
                        showCalendar = false
                        selectedDate = date
                    }
                }
            }
            .sheet(item: $selectedDate) { date in
                if let viewModel {
                    DailyStudyLogView(date: date, materials: viewModel.materials) {
                        viewModel.load(for: qualification)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(modelContext: modelContext)
            }
            viewModel?.load(for: qualification)
        }
        .onChange(of: qualification?.id) {
            viewModel?.load(for: qualification)
        }
    }
    
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
    
    private func mainContentView(viewModel: HomeViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                CountdownView(
                    daysUntilExam: viewModel.daysUntilExam,
                    onSetExamDate: {}
                )
                
                DailyQuotaView(
                    quotas: viewModel.materials.map { material in
                        let quota = viewModel.calculatedDailyQuota(for: material)
                        return (name: material.name, amount: quota, unit: material.unit)
                    }
                )
                
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
                
                StreakView(
                    streak: viewModel.currentStreak,
                    weeklyStudyDays: viewModel.weeklyStudyDays,
                    weeklyTargetDays: qualification?.weeklyTargetDays ?? 4
                )
                
                HeatmapView(data: viewModel.heatmapData()) {
                    showCalendar = true
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
