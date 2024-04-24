//
//  widget.swift
//  widget
//
//  Created by wxiaopang on 2024/4/23.
//

import Intents
import SwiftUI
import WidgetKit


// 自定义的其他数据...刷新时间和内容被封装在 TimelineEntry 对象中：
struct SimpleEntry: TimelineEntry {
    enum Time {
        case morning, afternoon, night
    }
    let date: Date
//    let saying: Saying
    let time: Time
}
struct Provider: TimelineProvider {
    private func randomEntry(_ date: Date = Date()) -> SimpleEntry {
//        SimpleEntry(date: date, saying: SayingManager.share.randomSaying,time: .morning)
        SimpleEntry(date: date, time: .morning)
    }
    //用户在第一次看到你的小组件时，系统会调用
    //func placeholder(in context: Context) -> SimpleEntry 方法，
    //要求同步返回一个时间线条目来展示小组件的占位，
    //让用户对小组件显示的内容有一个总体了解，通常你可以用一些保底数据来展示。
    func placeholder(in context: Context) -> SimpleEntry {
        randomEntry()
    }
    //随后会调用
    //func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void)，
    //WidgetKit 会要求程序提供预览快照，需要异步返回一个时间线条目展示小组件
    //    当然这个方法不仅在小组件库中展示时会调用，其他情况下也可能调用，可以用 context.isPreview 来判断当前是否在组件库中显示，如果是在组件库中展示，completion 需要及时返回，苹果没有说具体多久，但如果你的数据从网络获取，而且时间超过几秒时，你最好先用保底数据返回。
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let _entry = SimpleEntry(date: Date(), time: .morning)
        completion(randomEntry())
    }
//    在请求初始快照后，WidgetKit 调用 getTimeline(in:completion:) 以向提供程序请求定期时间线。
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []

        let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 8..<12:
                entries.append(SimpleEntry(date: Date(), time: .morning))
                entries.append(SimpleEntry(date: getDate(in: 12), time: .afternoon))
                entries.append(SimpleEntry(date: getDate(in: 18), time: .night))

            case 12..<18:
                entries.append(SimpleEntry(date: Date(), time: .afternoon))
                entries.append(SimpleEntry(date: getDate(in: 18), time: .night))

            default:
                entries.append(SimpleEntry(date: Date(), time: .night))
            }
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
    }
    func getDate(in hour: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }
}


struct TestEntryView: View {
    // 这句代码能从上下文环境中取到小组件的型号
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var familyString: String {
        switch family {
        case .systemSmall:
            return "小组件"
        case .systemMedium:
            return "中等组件"
        case .systemLarge:
            return "大号组件"
        case .systemExtraLarge:
            return "超大号组件"
        case .accessoryCircular:
            return "圆形组件"
        case .accessoryRectangular:
            return "方形组件"
        case .accessoryInline:
            return "内联小组件"
        @unknown default:
            return "其他类型小组件"
        }
    }
    
    var body: some View {
        @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground
        ZStack{
            if !showsWidgetContainerBackground {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 3)
            }
                Image("bg")
                    .resizable()
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
            VStack(spacing: 10) {
                Link(destination: URL(string: "iosnews://iosNews.com/p1=icon")!) {
                    Image(entry.time.icon)
                        .resizable()
                        .foregroundColor(.red)
                        .frame(width: 40,height: 40)
                }
                Link(destination: URL(string: "iosnews://iosNews.com/p1=icon")!) {
                    HStack {
                        Text("现在是:")
                        Text(entry.time.text)
                    }
                    .font(.subheadline)
                    Text("这是:\(familyString)")
                }
            }
        }
        .widgetURL(URL(string: "medium/widgeturl_root"))
    }
}


extension View {
    @ViewBuilder
    func widgetBackground(_ backgroundView: some View) -> some View {
        if Bundle.main.bundlePath.hasSuffix(".appex"){
            if #available(iOS 17.0, *) {
                containerBackground(for: .widget) {
                    backgroundView
                }
            } else {
                background(backgroundView)
            }
        } else {
            background(backgroundView)
        }
    }
}



@main
struct Test: Widget {
    let kind: String = "Test"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TestEntryView(entry: entry)
        }
        .configurationDisplayName("小组件的名称")
        .description("小组件的描述小组件的描述")
        .supportedFamilies(supportedFamilies)
        .contentMarginsDisabled()//关闭系统统一发放的边距
//        .containerBackground(for: .widget) {
//                    // 背景view
//                    Color.black
//            }
    }
    
    private var supportedFamilies:[WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ];
        }else {
            return [
                .systemSmall,
                .systemMedium,
                .systemLarge
            ]
        }
    }
}

struct Test_Previews: PreviewProvider {
    static var previews: some View {
        TestEntryView(entry: SimpleEntry(date: Date(), time: .morning))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}


public struct SayingManager {
    static let share = SayingManager()
    private init() {}

    private let list: [Saying] = [
        Saying(en: "To be both a speaker of words and a doer of deeds.", zh: "既当演说家，又做实干家"),
        Saying(en: "Variety is the spice of life.", zh: "变化是生活的调味品"),
        Saying(en: "There is no royal road to learning.", zh: "求知无坦途"),
        Saying(en: "Doubt is the key to knowledge.", zh: "怀疑是知识的钥匙"),
        Saying(en: "The greatest test of courage on earth is to bear defeat without losing heart.", zh: "世界上对勇气的最大考验是忍受失败而不丧失信心")
    ]

    var randomSaying: Saying {
        list.randomElement() ?? Saying(en: "There is no royal road to learning.", zh: "求知无坦途")
    }
}

public struct Saying {
    let en: String
    let zh: String
}

extension SimpleEntry.Time {
    var text: String {
        switch self {
        case .morning:
            return "上午"
        case .afternoon:
            return "下午"
        case .night:
            return "晚上"
        }
    }
    
    var icon: String {
        switch self {
        case .morning:
            return "01"
        case .afternoon:
            return "02"
        case .night:
            return "03"
        }
    }
}
