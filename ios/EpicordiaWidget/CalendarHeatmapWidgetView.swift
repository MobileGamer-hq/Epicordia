import WidgetKit
import SwiftUI

struct HeatmapWidgetPayload: Codable {
    let focus_rate: Int
    let window: String
}

struct HeatmapWidgetEntry: TimelineEntry {
    let date: Date
    let payload: HeatmapWidgetPayload
}

struct HeatmapWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeatmapWidgetEntry {
        HeatmapWidgetEntry(
            date: Date(),
            payload: HeatmapWidgetPayload(focus_rate: 82, window: "July 2026")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HeatmapWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HeatmapWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.epicordia.app")
        let jsonString = userDefaults?.string(forKey: "heatmap_data") ?? ""
        var payload = placeholder(in: context).payload

        if let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(HeatmapWidgetPayload.self, from: data) {
            payload = decoded
        }

        let entry = HeatmapWidgetEntry(date: Date(), payload: payload)
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct CalendarHeatmapWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HeatmapWidgetProvider.Entry

    var body: some View {
        switch family {
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Contribution Activity")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Less ■ ■ ■ ■ More")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }

                // Grid representation of contribution heatmap
                HStack(spacing: 3) {
                    ForEach(0..<14, id: \.self) { col in
                        VStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { row in
                                Rectangle()
                                    .fill((col + row) % 3 == 0 ? Color.blue.opacity(Double((col % 4) + 1) * 0.25) : Color.gray.opacity(0.15))
                                    .frame(width: 14, height: 14)
                                    .cornerRadius(2)
                            }
                        }
                    }
                }
            }
            .padding()
            .widgetURL(URL(string: "epicordia://calendar"))

        default: // systemLarge
            VStack(alignment: .leading, spacing: 10) {
                Text("Visual Workflow")
                    .font(.system(size: 16, weight: .bold))

                HStack {
                    VStack(alignment: .leading) {
                        Text("\(entry.payload.focus_rate)%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Focus Rate")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(entry.payload.window)
                            .font(.system(size: 14, weight: .semibold))
                        Text("Current Window")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Full Grid Matrix
                VStack(spacing: 3) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(0..<18, id: \.self) { col in
                                Rectangle()
                                    .fill((col * row) % 5 == 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.15))
                                    .frame(height: 12)
                                    .cornerRadius(2)
                            }
                        }
                    }
                }

                HStack {
                    Text("Mon").font(.system(size: 10)).foregroundColor(.gray)
                    Spacer()
                    Text("Wed").font(.system(size: 10)).foregroundColor(.gray)
                    Spacer()
                    Text("Fri").font(.system(size: 10)).foregroundColor(.gray)
                    Spacer()
                    Text("Sun").font(.system(size: 10)).foregroundColor(.gray)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                        Text("Design").font(.system(size: 10, weight: .medium))
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.blue.opacity(0.6)).frame(width: 6, height: 6)
                        Text("Code").font(.system(size: 10, weight: .medium))
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.purple.opacity(0.4)).frame(width: 6, height: 6)
                        Text("Meetings").font(.system(size: 10, weight: .medium))
                    }
                }
            }
            .padding()
            .widgetURL(URL(string: "epicordia://calendar"))
        }
    }
}

struct CalendarHeatmapWidget: Widget {
    let kind: String = "CalendarHeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeatmapWidgetProvider()) { entry in
            CalendarHeatmapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar Heatmap")
        .description("Visual activity density and focus rate trends.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
