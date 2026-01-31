import SwiftUI

struct MemoRowView: View {
    let memo: Memo
    let materials: [Material]
    let imageDataItems: [Data]
    
    private var materialName: String? {
        guard let materialId = memo.materialId else { return nil }
        return materials.first { $0.id == materialId }?.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            Text(memo.content)
                .font(.body)
                .lineLimit(5)
            
            if !imageDataItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<imageDataItems.count, id: \.self) { index in
                            if let uiImage = UIImage(data: imageDataItems[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            
            Text(memo.createdAt, format: .dateTime.month().day().hour().minute())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
