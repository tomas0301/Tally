import SwiftUI

struct MemoRowView: View {
    let memo: Memo
    let materials: [Material]
    
    private var materialName: String? {
        guard let materialId = memo.materialId else { return nil }
        return materials.first { $0.id == materialId }?.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 教材名タグ
            if let name = materialName {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // 本文
            Text(memo.content)
                .font(.body)
                .lineLimit(5)
            
            // 画像
            if !memo.imageFileNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(memo.imageFileNames, id: \.self) { fileName in
                            if let image = ImageStorage.load(fileName: fileName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            
            // 日時
            Text(memo.createdAt, format: .dateTime.month().day().hour().minute())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
