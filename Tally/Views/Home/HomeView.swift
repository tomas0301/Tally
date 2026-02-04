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
    @State private var showQuotaSettings = false

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
                MaterialEditView(
                    material: nil,
                    examDate: qualification?.examDate,
                    weeklyTargetDays: qualification?.weeklyTargetDays ?? 4,
                    onSave: { name, total, unit, quota, quotaMode, deadline, useWeeklyTarget in
                        viewModel?.addMaterial(name: name, totalAmount: total, unit: unit, dailyQuota: quota, quotaMode: quotaMode, deadline: deadline, useWeeklyTarget: useWeeklyTarget)
                    }
                )
            }
            .sheet(item: $editingMaterial) { material in
                MaterialEditView(
                    material: material,
                    examDate: qualification?.examDate,
                    weeklyTargetDays: qualification?.weeklyTargetDays ?? 4,
                    onSave: { name, total, unit, quota, quotaMode, deadline, useWeeklyTarget in
                        viewModel?.updateMaterial(material, name: name, totalAmount: total, unit: unit, dailyQuota: quota, quotaMode: quotaMode, deadline: deadline, useWeeklyTarget: useWeeklyTarget)
                    }
                )
            }
            .sheet(isPresented: $showCalendar) {
                if let viewModel {
                    StudyCalendarView(materials: viewModel.materials, onSelectDate: { date in
                        showCalendar = false
                        selectedDate = date
                    }, onUpdate: {
                        viewModel.load(for: qualification)
                    })
                }
            }
            .sheet(item: $selectedDate) { date in
                if let viewModel {
                    DailyStudyLogView(date: date, materials: viewModel.materials) {
                        viewModel.load(for: qualification)
                    }
                }
            }
            .sheet(isPresented: $showQuotaSettings) {
                if let viewModel {
                    QuotaSettingsView(
                        materials: viewModel.materials,
                        qualification: qualification,
                        onUpdate: {
                            viewModel.load(for: qualification)
                        }
                    )
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
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "book.closed.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.primary.opacity(0.2))
            
            VStack(spacing: 8) {
                Text("教材がありません")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.textPrimary)
                
                Text("教材を追加して\n学習を始めましょう")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Button {
                showAddMaterial = true
            } label: {
                Text("教材を追加")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            Spacer()
        }
        .padding()
        .background(Theme.background)
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
                        let today = viewModel.todayAmount(for: material)
                        return (name: material.name, todayAmount: today, quota: quota, unit: material.unit)
                    },
                    onTap: {
                        showQuotaSettings = true
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
                        
                        if material.id != viewModel.materials.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .modifier(Theme.shadow())

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
        .background(Theme.background)
    }
}
