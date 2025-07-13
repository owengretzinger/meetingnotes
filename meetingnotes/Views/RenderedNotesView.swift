import SwiftUI

struct RenderedNotesView: View {
    let text: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(text.split(separator: "\n"), id: \.self) { line in
                    self.renderLine(String(line))
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            EmptyView()
        } else if let level = headingLevel(for: trimmed) {
            let content = String(trimmed.dropFirst(level + 1)).trimmingCharacters(in: .whitespaces)
            Text(content)
                .font(.system(size: CGFloat(18 - level * 2), weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let (indentLevel, bullet, content) = listItemInfo(for: line) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(bullet)
                    .foregroundColor(.secondary)
                Text(content)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, CGFloat(indentLevel * 15))
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(trimmed)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func headingLevel(for line: String) -> Int? {
        guard line.hasPrefix("#") else { return nil }
        var count = 0
        for char in line {
            if char == "#" {
                count += 1
            } else if char == " " {
                return count
            } else {
                return nil
            }
        }
        return nil
    }
    
    private func listItemInfo(for line: String) -> (indentLevel: Int, bullet: String, content: String)? {
        let leadingSpaces = line.prefix(while: { $0 == " " }).count
        let indentLevel = leadingSpaces / 4
        
        let remaining = String(line.dropFirst(leadingSpaces))
        
        if remaining.hasPrefix("- ") {
            return (indentLevel, getBullet(for: indentLevel), String(remaining.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        } else if remaining.hasPrefix("* ") {
            return (indentLevel, getBullet(for: indentLevel), String(remaining.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        } else if let dotIndex = remaining.firstIndex(of: "."), let num = Int(remaining[remaining.startIndex..<dotIndex]), remaining[dotIndex..<remaining.endIndex].hasPrefix(". ") {
            let contentStart = remaining.index(dotIndex, offsetBy: 2)
            return (indentLevel, "\(num).", String(remaining[contentStart...]).trimmingCharacters(in: .whitespaces))
        }
        return nil
    }
    
    private func getBullet(for level: Int) -> String {
        switch level % 3 {
        case 0: return "•"
        case 1: return "◦"
        case 2: return "▪︎"
        default: return "-"
        }
    }
}

#Preview {
    RenderedNotesView(text: "# Heading 1\n## Heading 2\n- List item\n  - Nested item\n    - Deeper item\n1. Ordered\n  1. Nested ordered\nNormal text")
} 