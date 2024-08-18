import Foundation
import SwiftUI

struct SectionKeyValueView: View {
    var icon: String?
    var key: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
#if os(macOS)
            HStack (alignment: .center) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(Color(NSColor.secondaryLabelColor))
                }
                Text(key)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color(NSColor.secondaryLabelColor))
                Spacer()
                Text(value)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
            }
#else
            HStack (alignment: .top) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .padding(.top, 4)
                }
                VStack(alignment: .leading) {
                    Text(key)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    Text(value)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
#endif
        }
    }
}
