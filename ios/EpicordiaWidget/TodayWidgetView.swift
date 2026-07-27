import WidgetKit
import SwiftUI

struct TodayTaskItem: Codable, Identifiable {
    let id: String
    let title: String
    let time: String
    let completed: Bool
}

struct TodayWidgetPayload: Codable {
    let due_count: Int
    let tasks: [TodayTaskItem]
    let activity_14_days: [Int]
}

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let payload: TodayWidgetPayload
}

struct TodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(
            date: Date(),
            payload: TodayWidgetPayload(
                due_count: 3,
                tasks: [
                    TodayTaskItem(id: "1", title: "Finalize UX Audit", time: "10:00 AM", completed: false),
                    TodayTaskItem(id: "2", title: "Draft system tokens", time: "2:30 PM", completed: false),
                    TodayTaskItem(id: "3", title: "Review docs", time: "4:00 PM", completed: false)
                ],
                activity_14_days: [0, 1, 3, 2, 0, 4, 2, 5, 1, 0, 2, 3, 4, 2]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.epicordia.app")
        let jsonString = userDefaults?.string(forKey: "today_data") ?? ""
        var payload = placeholder(in: context).payload

        if let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(TodayWidgetPayload.self, from: data) {
            payload = decoded
        }

        let entry = TodayWidgetEntry(date: Date(), payload: payload)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct TodayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TodayWidgetProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 12) {
                Text("\(entry.payload.due_count) due today")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.blue)

                Spacer()

                if let firstTask = entry.payload.tasks.first {
                    HStack(spacing: 6) {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(firstTask.title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .widgetURL(URL(string: "epicordia://today"))

        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Link(destination: URL(string: "epicordia://today")!) {
                        Text("View All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }

                Divider()

                ForEach(entry.payload.tasks.prefix(3)) { task in
                    HStack {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(task.title)
                            .font(.system(size: 13))
                            .lineLimit(1)
                        Spacer()
                        if !task.time.isEmpty {
                            Text(task.time)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding()
            .widgetURL(URL(string: "epicordia://today"))

        default: // Large
            VStack(alignment: .leading, spacing: 10) {
                Text("Activity & Tasks")
                    .font(.system(size: 16, weight: .bold))

                Divider()

                ForEach(entry.payload.tasks.prefix(6)) { task in
                    HStack {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(task.title)
                            .font(.system(size: 13))
                            .lineLimit(1)
                        Spacer()
                        if !task.time.isEmpty {
                            Text(task.time)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity (14 days)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        ForEach(0..<min(14, entry.payload.activity_14_days.count), id: \.self) { idx in
                            Rectangle()
                                .fill(entry.payload.activity_14_days[idx] > 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.2))
                                .frame(height: 12)
                                .cornerRadius(2)
                        }
                    }
                }
            }
            .padding()
            .widgetURL(URL(string: "epicordia://today"))
        }
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today Widget")
        .description("Glanceable task overview for your day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
