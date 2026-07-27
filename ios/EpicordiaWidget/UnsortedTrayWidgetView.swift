import WidgetKit
import SwiftUI

struct UnsortedWidgetPayload: Codable {
    let count: Int
    let items: [String]
}

struct UnsortedWidgetEntry: TimelineEntry {
    let date: Date
    let payload: UnsortedWidgetPayload
}

struct UnsortedWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UnsortedWidgetEntry {
        UnsortedWidgetEntry(
            date: Date(),
            payload: UnsortedWidgetPayload(
                count: 5,
                items: ["Buy coffee beans", "Research AI tools", "Fix navbar bug"]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UnsortedWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UnsortedWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.epicordia.app")
        let jsonString = userDefaults?.string(forKey: "unsorted_data") ?? ""
        var payload = placeholder(in: context).payload

        if let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(UnsortedWidgetPayload.self, from: data) {
            payload = decoded
        }

        let entry = UnsortedWidgetEntry(date: Date(), payload: payload)
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct UnsortedTrayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: UnsortedWidgetProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "tray")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                Text("\(entry.payload.count) unsorted")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                Spacer()
            }
            .widgetURL(URL(string: "epicordia://unsorted"))

        default: // systemMedium
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 4) {
                    Text("\(entry.payload.count)")
                        .font(.system(size: 32, weight: .bold))
                    Text("UNSORTED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
                .frame(width: 80)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.payload.items.prefix(3), id: \.self) { item in
                        Text("• \(item)")
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding()
            .widgetURL(URL(string: "epicordia://unsorted"))
        }
    }
}

struct UnsortedTrayWidget: Widget {
    let kind: String = "UnsortedTrayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnsortedWidgetProvider()) { entry in
            UnsortedTrayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Unsorted Tray")
        .description("Quick preview of unfiled tasks & notes.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
