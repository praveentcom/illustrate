import SwiftUI

struct SectionKeyValueView<T: View>: View {
    var customValueView: T
    var useCustomValueView: Bool

    var icon: String?
    var key: String
    var value: String
    var monospaced: Bool?

    init(icon: String? = nil, key: String, value: String, customValueView: T? = nil, monospaced: Bool? = nil) {
        self.icon = icon
        self.key = key
        self.value = value
        self.monospaced = monospaced

        if let customValueView = customValueView {
            self.customValueView = customValueView
            useCustomValueView = true
        } else {
            self.customValueView = EmptyView() as! T
            useCustomValueView = false
        }
    }

    init(icon: String? = nil, key: String, value: String, monospaced: Bool? = nil) where T == EmptyView {
        self.init(icon: icon, key: key, value: value, customValueView: nil, monospaced: monospaced)
    }

    var body: some View {
        VStack(alignment: .leading) {
            #if os(iOS)

                HStack(alignment: .top) {
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
                        if useCustomValueView {
                            customValueView
                        } else {
                            Text(value)
                                .font(.body)
                                .monospaced(monospaced ?? false)
                        }
                    }
                    Spacer()
                }
            #else
                HStack(alignment: .center) {
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
                    if useCustomValueView {
                        customValueView
                    } else {
                        Text(value)
                            .font(.body)
                            .multilineTextAlignment(.trailing)
                            .monospaced(monospaced ?? false)
                    }
                }
            #endif
        }
    }
}
