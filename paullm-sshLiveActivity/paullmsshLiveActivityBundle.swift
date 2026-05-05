#if os(iOS)
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
@main
struct paullmsshLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        paullmsshLiveActivityWidget()
    }
}
#endif
