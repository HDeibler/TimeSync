

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var showingSettings = false
    @State private var apiKeyExists: Bool = UserDefaultsManager.apiKeyExists
    @State private var showingAdditionalButtons = false
    @State private var showingEventForm = false


    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                NavigationView {
                    TabView {
                        DashboardView().tabItem {
                            Label("Dashboard", systemImage: "checkmark.seal")
                        }
                        CalendarView().tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                        AssignmentsView().tabItem {
                            Label("Assignments", systemImage: "list.bullet")
                        }
                    }
                    .navigationBarItems(trailing: Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                    })
                    .blur(radius: showingAdditionalButtons ? 10 : 0)
                }
                .disabled(showingAdditionalButtons)
                .blur(radius: showingAdditionalButtons ? 10 : 0)
                
                if showingAdditionalButtons {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                showingAdditionalButtons = false
                            }
                        }
                        .zIndex(1)
                }
                
                MainActionButton(showingAdditionalButtons: $showingAdditionalButtons)
                    .padding(20)
                    .position(x: showingAdditionalButtons ? geometry.size.width / 2 : geometry.size.width - 44, y: geometry.size.height - (getTabBarHeight() + 30))
                    .animation(.easeOut, value: showingAdditionalButtons)
                    .zIndex(2)
                
                if showingAdditionalButtons {
                    VStack(spacing: 15) {
                        MenuButton(label: "New Event", icon: "calendar.badge.plus") {
                            self.showingEventForm = true
                        }
                        
                        MenuButton(label: "AI Schedule Creation", icon: "calendar.badge.plus") {
                            CoreDataManager.shared.fetchStudySchedule()
                        }
                        
                    }
                    .transition(.opacity)
                    .animation(.easeOut, value: showingAdditionalButtons)
                    .padding(.bottom, getTabBarHeight() + 60)
                    .zIndex(2)
                }
            }
        }
        .sheet(isPresented:$showingSettings) {
            SettingsView(apiKeyExists:$apiKeyExists)
        }
        .sheet(isPresented: $showingEventForm) {
            AddEventView()
        }
    }
    
    private func getTabBarHeight() -> CGFloat {
        return 50
    }
    
}

struct MenuButton: View {
    var label: String
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundColor(.black).font(.headline).padding()
                Spacer()
                Image(systemName: icon).foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 2)
            .padding(5)
        }
    }
}

struct MainActionButton : View{
    @Binding var showingAdditionalButtons : Bool
    
    var body:some View{
        Button(action:{
            withAnimation{
                self.showingAdditionalButtons.toggle()
            }
        }){
            Image(systemName:self.showingAdditionalButtons ?"xmark":"plus").resizable().frame(width :24,height :24).padding().foregroundColor(Color.white).background(self.showingAdditionalButtons ?GlobalColors.lightorange_highlight3 :GlobalColors.darkorange_highlight2 ).clipShape(Circle()).shadow(radius :4)
        }
    }
}


struct AddEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var context
    
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var startTimeSelection = TimeSelection()
    @State private var endTimeSelection = TimeSelection()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Event Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Section(header: Text("Start Time")) {
                    TimePickerView(timeSelection: $startTimeSelection)
                }
                
                Section(header: Text("End Time")) {
                    TimePickerView(timeSelection: $endTimeSelection)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    let startTime = startTimeSelection.formatted
                    let endTime = endTimeSelection.formatted
                    CoreDataManager.shared.addEvent(title: title, date: date, startTime: startTime, endTime: endTime, isFromChatGPT: false)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
}

struct TimeSelection {
    var hour: Int = 12
    var minute: Int = 0
    var period: String = "AM"
    
    var formatted: String {
    
        let formattedHour = hour == 12 || hour == 0 ? "12" : "\(hour)"
        return String(format: "%@:%02d %@", formattedHour, minute, period)
    }
}
struct TimePickerView: View {
    @Binding var timeSelection: TimeSelection
    
    var body: some View {
        HStack {
            Picker("Hour", selection: $timeSelection.hour) {
                ForEach(1..<13, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Text(":")
            
            Picker("Minute", selection: $timeSelection.minute) {
                ForEach(0..<60, id: \.self) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Picker("AM/PM", selection: $timeSelection.period) {
                Text("AM").tag("AM")
                Text("PM").tag("PM")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}




    
    struct ContentView_Previews : PreviewProvider {
        static var previews:some View{
            ContentView()
        }
        
    }
    
    
