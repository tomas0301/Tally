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
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Text(memo.content.replacingOccurrences(of: "\n", with: " "))
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
            
            Text(dateString)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .modifier(Theme.shadow())
        .padding(.horizontal, 4)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: memo.createdAt)
    }
}
