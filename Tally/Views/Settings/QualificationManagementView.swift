import SwiftUI

struct QualificationManagementView: View {
    let qualificationVM: QualificationViewModel
    @State private var showAddQualification = false
    @State private var editingQualification: Qualification?
    
    var body: some View {
        List {
            Section("選択中の資格") {
                if let selected = qualificationVM.selectedQualification {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                        Text(selected.name)
                            .fontWeight(.semibold)
                    }
                } else {
                    Text("未選択")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("登録済みの資格") {
                ForEach(qualificationVM.qualifications, id: \.id) { q in
                    Button {
                        qualificationVM.selectQualification(q)
                    } label: {
                        HStack {
                            Image(systemName: q.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(q.isSelected ? .blue : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(q.name)
                                    .foregroundStyle(.primary)
                                if let examDate = q.examDate {
                                    Text("試験日: \(examDate, format: .dateTime.year().month().day())")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            qualificationVM.deleteQualification(q)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        Button {
                            editingQualification = q
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
            
            Section {
                Button {
                    showAddQualification = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("資格を追加")
                    }
                }
            }
        }
        .navigationTitle("資格管理")
        .sheet(isPresented: $showAddQualification) {
            NavigationStack {
                QualificationEditView { name, examDate, weeklyTarget, quotaMode in
                    qualificationVM.addQualification(name: name, examDate: examDate, weeklyTargetDays: weeklyTarget, quotaMode: quotaMode)
                }
            }
        }
        .sheet(item: $editingQualification) { q in
            NavigationStack {
                QualificationEditView(qualification: q) { name, examDate, weeklyTarget, quotaMode in
                    qualificationVM.updateQualification(q, name: name, examDate: examDate, weeklyTargetDays: weeklyTarget, quotaMode: quotaMode)
                }
            }
        }
    }
}
