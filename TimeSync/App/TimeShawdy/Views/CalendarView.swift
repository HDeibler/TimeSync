import SwiftUI
import CoreData
import Combine


extension Date {
    func startOfWeek(using calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)
    }
    
    func isToday(using calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(self)
    }
    
    func isSameDay(as date: Date, using calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: date)
    }
    
    func daysInMonth(using calendar: Calendar = .current) -> Int {
        let range = calendar.range(of: .day, in: .month, for: self)!
        return range.count
    }
    
    func firstDayOfMonth(using calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }
    
    func weekDayIndex(using calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.weekday], from: self)
        return (components.weekday! - calendar.firstWeekday + 7) % 7
    }
    
    func startOfDay(using calendar: Calendar = .current) -> Date {
        return calendar.startOfDay(for: self)
    }
    
}


class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        CoreDataManager.shared.eventsDidChange
            .sink { [weak self] in
                self?.loadEvents()
            }
            .store(in: &cancellables)
    }

    func loadEvents() {
        self.events = CoreDataManager.shared.fetchAllCalendarEvents()
    }

    func addEvent(title: String, date: Date, startTime: String, endTime: String) {
        CoreDataManager.shared.addEvent(title: title, date: date, startTime: startTime, endTime: endTime, isFromChatGPT: false)
        loadEvents()
    }


}


struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var currentDate = Date()
    @State private var showWeekView = false
    @State private var selectedDay: Date? = Date()
    
    var calendar: Calendar = .current
    let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(alignment: .center, spacing: 0) {
                CalendarHeaderView(currentDate: $currentDate, showWeekView: $showWeekView, formatter: yearMonthFormatter)
                WeekDaysHeaderView()
                if showWeekView {
                    WeekView(currentDate: $currentDate, selectedDay: $selectedDay, events: viewModel.events)
                } else {
                    MonthView(currentDate: $currentDate, selectedDay: $selectedDay, events: viewModel.events)
                }
                EventsListView(selectedDate: selectedDay, events: viewModel.events, viewModel: viewModel)
                Spacer()
            }
            .padding()
            .animation(.easeInOut, value: showWeekView)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                viewModel.loadEvents()
            }
        }
    }
}


struct CalendarHeaderView: View {
    @Binding var currentDate: Date
    @Binding var showWeekView: Bool
    let formatter: DateFormatter
    var calendar = Calendar.current
    
    
    var body: some View {
        HStack {
            Button(action: { self.changePeriod(by: -1) }) {
                Image(systemName: "chevron.left").font(.title)
            }
            Spacer()
            Text(formatter.string(from: currentDate)).font(.title)
            Button(action: { self.showWeekView.toggle() }) {
                Image(systemName: "chevron.down").rotationEffect(Angle(degrees: showWeekView ? 180 : 0))
            }
            Spacer()
            Button(action: { self.changePeriod(by: 1) }) {
                Image(systemName: "chevron.right").font(.title)
            }
        }
    }
    

    private func changePeriod(by value: Int) {
        if showWeekView {
            // Change by a week
            if let newDate = calendar.date(byAdding: .weekOfYear, value: value, to: currentDate) {
                currentDate = newDate
            }
        } else {
            // Change by a month
            if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
                currentDate = newDate
            }
        }
    }
}


struct WeekDaysHeaderView: View {
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        HStack {
            ForEach(days, id: \.self) { day in
                Text(day).frame(maxWidth: .infinity)
            }
        }
    }
}


struct MonthView: View {
    @Binding var currentDate: Date
    @Binding var selectedDay: Date?
    var events: [CalendarEvent]
    let calendar: Calendar = .current
    
    var body: some View {
        let daysInMonth = currentDate.daysInMonth(using: calendar)
        let firstDayOfMonth = currentDate.firstDayOfMonth(using: calendar)!
        let startingSpaces = firstDayOfMonth.weekDayIndex(using: calendar)
        
        LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 15) {
            ForEach(0..<daysInMonth + startingSpaces, id: \.self) { index in
                if index >= startingSpaces {
                    let dayOffset = index - startingSpaces
                    if let dateForDay = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                        DayView(
                            day: dateForDay,
                            isToday: dateForDay.isToday(using: calendar),
                            isSelected: selectedDay?.isSameDay(as: dateForDay, using: calendar) ?? false,
                            hasEvents: events.contains { $0.date?.startOfDay(using: calendar) == dateForDay.startOfDay(using: calendar) },
                            action: {
                                self.selectedDay = dateForDay
                            }
                        )
                    }
                } else {
                    Text("").frame(height: 44)
                }
            }
        }
    }
}


struct WeekView: View {
    @Binding var currentDate: Date
    @Binding var selectedDay: Date?
    var events: [CalendarEvent]
    let calendar: Calendar = .current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 15) {
            ForEach(0..<7, id: \.self) { index in
                if let startOfWeek = currentDate.startOfWeek(using: calendar),
                   let dateForDay = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                    DayView(
                        day: dateForDay,
                        isToday: dateForDay.isToday(using: calendar),
                        isSelected: selectedDay?.isSameDay(as: dateForDay, using: calendar) ?? false,
                        hasEvents: events.contains { $0.date?.startOfDay(using: calendar) == dateForDay.startOfDay(using: calendar) },
                        action: {
                            self.selectedDay = dateForDay
                        }
                    )
                }
            }
        }
        .padding(.bottom, 20)
    }
}




struct EventsListView: View {
    var selectedDate: Date?
    var events: [CalendarEvent]
    let calendar = Calendar.current
    @ObservedObject var viewModel: CalendarViewModel

    private var filteredEventsForSelectedDate: [CalendarEvent] {
        guard let selectedDate = selectedDate else { return [] }
        return events.filter { event in
            guard let eventDate = event.date else { return false }
            return Calendar.current.isDate(eventDate, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        let timeSlots = generateTimeSlots()
        VStack {
        
            
            let totalHeight = CGFloat(timeSlots.count * 60)
            ScrollViewReader { value in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(timeSlots, id: \.id) { slot in
                            TimeSlotView(time: slot.time, events: slot.events, viewModel: viewModel)
                                .id(slot.id)
                        }
                    }
                    .overlay(
                        CurrentTimeIndicator(totalHeight: totalHeight)
                            .frame(height: totalHeight), alignment: .topLeading
                    )
                }
                .onAppear {
                    scrollToCurrentTime(using: value)
                }
            }
        }
    }

 
    private func generateTimeSlots() -> [TimeSlot] {
        var slots = [TimeSlot]()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        for hour in 0..<24 {
            for minute in [0, 15, 30, 45] {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                if let date = Calendar.current.date(from: components) {
                    let timeString = formatter.string(from: date)
                    let matchingEvents = filteredEventsForSelectedDate.filter { $0.startTime == timeString }
                    let slot = TimeSlot(id: UUID().uuidString, time: timeString, events: matchingEvents)
                    slots.append(slot)
                }
            }
        }

        return slots
    }
    private func scrollToCurrentTime(using scrollViewReader: ScrollViewProxy) {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentMinute = Calendar.current.component(.minute, from: Date())
        let scrollToId = String(format: "%02d%02d", currentHour, currentMinute < 30 ? 00 : 30)
        scrollViewReader.scrollTo(scrollToId, anchor: .center)
    }


    struct TimeSlot: Identifiable {
        let id: String
        let time: String
        var events: [CalendarEvent]
    }
}


struct TimeSlotView: View {
    let time: String
    var events: [CalendarEvent]
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack {
            ForEach(events, id: \.self) { event in
                HStack {
                    VStack(alignment: .leading) {
                        Text(event.title ?? "Event")
                            .font(.headline)
                            .foregroundColor(.white)
                            .strikethrough(event.completed, color: .white)
                        Text("Time: \(event.startTime ?? "") - \(event.endTime ?? "")")
                            .font(.caption)
                            .foregroundColor(.white)
                        if event.isFromChatGPT {
                            Text("AI Generated Study Time")
                                .font(.footnote)
                                .foregroundColor(.yellow)
                        }
                    }
                    Spacer()
                    
                    Button(action: {
                        toggleCompleted(for: event)
                    }) {
                        Image(systemName: event.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(event.completed ? .green : .white)
                    }
                }
                .padding()
                .frame(width: 330, alignment: .leading)
                .background(event.isFromChatGPT ? GlobalColors.darkblue_heading1 : GlobalColors.darkorange_highlight2)
                .cornerRadius(5)
                .padding(.bottom, 10)
            }
        }
        .padding(.horizontal)
    }
    
    private func toggleCompleted(for event: CalendarEvent) {
        CoreDataManager.shared.toggleEventCompleted(eventID: event.id!)
        
    }

}
struct CurrentTimeIndicator: View {
    let totalHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let currentTime = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: currentTime)
            let minute = calendar.component(.minute, from: currentTime)
            let dayFraction = CGFloat(hour * 60 + minute) / (24 * 60)
            let yPosition = dayFraction * totalHeight
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: yPosition))
                path.addLine(to: CGPoint(x: geometry.size.width, y: yPosition))
            }
            .stroke(Color.red, lineWidth: 2)
        }
    }
}


extension Date {
    func minuteOfDay() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}



struct DayView: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                HStack(alignment: .center, spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: day))")
                    if hasEvents {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(minWidth: 30, minHeight: 30)
            }
            .background(isToday ? GlobalColors.darkblue_heading1 : isSelected ? GlobalColors.lightorange_highlight3 : Color.clear)
            .clipShape(Circle())
            .foregroundColor(isToday ? .white : .black)
            .overlay(
                isSelected ? Circle().stroke(GlobalColors.lightorange_highlight3, lineWidth: 2) : nil
            )
        }
    }
}


struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
   
        CalendarView()
    }
}



func addEvent(title: String, date: Date, startTime: String, endTime: String, context: NSManagedObjectContext) {
    let newEvent = CalendarEvent(context: context)
    newEvent.id = UUID()
    newEvent.title = title
    newEvent.date = date
    newEvent.startTime = startTime
    newEvent.endTime = endTime
    
    do {
        try context.save()
    } catch {
        
        print("Failed to save the manual event: \(error.localizedDescription)")
    }
}

