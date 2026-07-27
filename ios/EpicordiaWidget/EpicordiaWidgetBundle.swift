import WidgetKit
import SwiftUI

@main
struct EpicordiaWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        QuickCaptureWidget()
        UnsortedTrayWidget()
        CalendarHeatmapWidget()
    }
}
