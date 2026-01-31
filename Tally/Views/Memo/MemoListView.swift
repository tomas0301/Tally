import SwiftUI
import SwiftData

struct MemoListView: View {
    @Environment(\.modelContext) private var modelContext
    let qualificationVM: QualificationViewModel
    @State private var viewModel: MemoViewModel?
    @State private var showCreateMemo = false
    
    private var qualificationId: UUID? {
        qualificationVM.selectedQualification?.id
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    if viewModel.memos.isEmpty {
                        emptyStateView
                    } else {
                        memoList(viewModel: viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("メモ")
            .overlay(alignment: .bottomTrailing) {
                if qualificationId != nil {
                    Button {
                        showCreateMemo = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showCreateMemo) {
                if let viewModel, let qId = qualificationId {
                    MemoEditView(
                        materials: viewModel.materials(for: qId),
                        onSave: { content, materialId, images in
                            viewModel.addMemo(qualificationId: qId, materialId: materialId, content: content, images: images)
                        }
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MemoViewModel(modelContext: modelContext)
            }
            viewModel?.load(for: qualificationId)
        }
        .onChange(of: qualificationId) {
            viewModel?.load(for: qualificationId)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("学習メモを残して\n気づきを記録しましょう")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
    
    private func memoList(viewModel: MemoViewModel) -> some View {
        List {
            ForEach(viewModel.memos, id: \.id) { memo in
                MemoRowView(memo: memo, materials: viewModel.materials(for: qualificationId))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteMemo(memo)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}
