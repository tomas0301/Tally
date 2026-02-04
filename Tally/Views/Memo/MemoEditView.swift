import SwiftUI
import PhotosUI

struct MemoEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let materials: [Material]
    let onSave: (String, UUID?, [UIImage]) -> Void
    var defaultMaterialId: UUID? = nil

    @State private var content: String = ""
    @State private var selectedMaterialId: UUID?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @FocusState private var isContentFocused: Bool

    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("メモ") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .focused($isContentFocused)
                }
                
                Section("教材（任意）") {
                    Picker("教材", selection: $selectedMaterialId) {
                        Text("なし").tag(UUID?.none)
                        ForEach(materials, id: \.id) { material in
                            Text(material.name).tag(UUID?.some(material.id))
                        }
                    }
                }
                
                Section("画像（任意）") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("画像を選択")
                        }
                    }
                    
                    if !images.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<images.count, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: images[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button {
                                            images.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.white, Theme.accent)
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("メモを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("投稿") {
                        onSave(content.trimmingCharacters(in: .whitespacesAndNewlines), selectedMaterialId, images)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: selectedPhotos) {
                Task {
                    images = []
                    for item in selectedPhotos {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            images.append(uiImage)
                        }
                    }
                }
            }
            .onAppear {
                isContentFocused = true
                if selectedMaterialId == nil {
                    selectedMaterialId = defaultMaterialId
                }
            }
        }
    }
}
