import SwiftUI
import SpriteKit
import CoreData
import Magnetic
import ObjectiveC
import UIKit

struct SetupView: View {
    @StateObject var viewModel = AppSetupViewModel()
    @State private var isGettingStarted = false // NEW: Track if the user has started the setup process
    @State private var setupCompleted = false
    @State private var userName: String = ""
    @State private var isLoadingAssignments = false
    @State private var selectedDays: Set<String> = Set()
    @State private var allDays = ["M", "T", "W", "Th", "F", "S", "SUN"]
    
    var body: some View {
        ZStack {
            
            
            VStack {
                if !isGettingStarted {
                    Spacer()
                    
                
                    Circle()
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .shadow(radius: 10)
                        .overlay(
                            Image("logo1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        )
                        .padding(.bottom, 20)
                    Button("Let's Get Started") {
                        isGettingStarted = true
                    }
                    .buttonStyle(FilledButton())
                    .padding()
                    .font(GlobalFonts.mainHeading(size: 18))
                    
                    Spacer()
                    
                } else if let currentStep = viewModel.setupSteps.first(where: { !$0.isCompleted }) {
                    // Setup process is underway
                    
                    setupCardView(for: currentStep)
                } else {
                    
                    ContentView()
                }
            }
            GeometryReader { geometry in
                TemporaryErrorMessageView(errorMessage: $viewModel.errorMessage)
                    .frame(width: geometry.size.width, height: 50, alignment: .top)
                    .offset(y: geometry.safeAreaInsets.top)
                    .edgesIgnoringSafeArea(.top)
            }
        }
        .globalBackground()
       
    }
    
    private func currentStepIndex() -> Int {
        viewModel.setupSteps.firstIndex(where: { !$0.isCompleted }) ?? viewModel.setupSteps.count - 1
    }
    
    private func nextStepTitle() -> String? {
        let index = currentStepIndex() + 1
        guard index < viewModel.setupSteps.count else { return nil }
        return viewModel.setupSteps[index].title
    }
    
    @ViewBuilder
    private func setupCardView(for step: SetupStep) -> some View {
        VStack(alignment: .center, spacing: 15) {
         
            HStack {
                Text(step.title)
                    .font(GlobalFonts.mainHeading(size: 22))
                    .foregroundColor(GlobalColors.darkblue_heading1)
                
                if step.title == "API Key Setup" {
                    Image(systemName: "link.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(GlobalColors.darkblue_heading1)
                        .onTapGesture {
                            if let url = URL(string: "mylink"), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                }
            }
            .padding(.bottom, 5)
            
           
            Text(step.instruction)
                .font(GlobalFonts.subHeading(size: 16, italic: true))
                .foregroundColor(GlobalColors.darkorange_highlight2)
                .padding(.bottom, 10)
            
     
            if viewModel.isLoading {
                ProgressView("Loading your Canvas Data...")
                    .padding()
            } else {
                stepSpecificContent(for: step)
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [GlobalColors.blue_highlight1, GlobalColors.lightorange_highlight3]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func stepSpecificContent(for step: SetupStep) -> some View {
        switch step.title {
        case "API Key Setup":
            TextField("API Key", text: $viewModel.apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
            
            Button("Save") {
                step.action?()
            }
            .buttonStyle(FilledButton())
            .disabled(viewModel.apiKey.isEmpty)
            
        case "Course Priority":
            enrollmentsView()
            
        case "Class Schedule":
            ScheduleInputView()
            
        case "Days you Don't Study":
            BlackoutDaysSettingView()
            
        default:
            EmptyView()
        }
    }
    
    private func enrollmentsView() -> some View {
        GeometryReader { geometry in
            MagneticViewWrapper(enrollments: viewModel.enrollments, size: geometry.size) { selectedEnrollment in
               
                if let index = viewModel.enrollments.firstIndex(where: { $0.id == selectedEnrollment.id }) {
                    withAnimation {
                        viewModel.removeEnrollment(at: index)
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder
    private func ScheduleInputView() -> some View {
        if let index = viewModel.selectedCourseIndex, viewModel.courses.indices.contains(index) {
            let courseDetail = viewModel.courses[index]
            
            
            let timeFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter
            }()
            
            VStack {
                Text((courseDetail.name))
                    .font(GlobalFonts.subHeading(size: 20))
                    .padding()
                
                daysSelectionView(selectedDaysString: $viewModel.tempClassDays)
                    
            
                HStack(spacing: 20) {
                    // Start Time Picker
                    VStack {
                        Text("Start Time")
                            .font(GlobalFonts.subHeading(size: 15))
                        
                        
                        DatePicker("", selection: Binding(
                            get: {
                                timeFormatter.date(from: viewModel.tempClassTimeStart) ?? Date()
                            },
                            set: { newDate in
                                viewModel.tempClassTimeStart = timeFormatter.string(from: newDate)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        
                    }
                    
                 
                    VStack {
                        Text("End Time")
                            .font(GlobalFonts.subHeading(size: 15))
                        
                        
                        DatePicker("", selection: Binding(
                            get: {
                                timeFormatter.date(from: viewModel.tempClassTimeEnd) ?? Date()
                            },
                            set: { newDate in
                                viewModel.tempClassTimeEnd = timeFormatter.string(from: newDate)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        
                    }
                }
                .padding(.horizontal)
                
                Button("Save") {
                   
                    viewModel.updateCourse(
                        courseId: courseDetail.id,
                        newClassDays: viewModel.tempClassDays,
                        newClassTimeStart: viewModel.tempClassTimeStart,
                        newClassTimeEnd: viewModel.tempClassTimeEnd
                    )
                }
                .buttonStyle(FilledButton())
                .padding()
            }
            .onAppear() {
                viewModel.selectNextCourseForUpdate()
                let tempDays = viewModel.tempClassDays
                selectedDays = []
                allDays.forEach { dayCode in
                    if tempDays.contains(dayCode) {
                        selectedDays.insert(dayCode)
                    }
                }
                
            }
        } else {
            Text("Please select a course to update its schedule.")
                .padding()
        }
    }
    
    
    @ViewBuilder
    private func daysSelectionView(selectedDaysString: Binding<String>) -> some View {

        
        
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(allDays, id: \.self) { day in
                        Button(action: {
                        
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                            
                            selectedDaysString.wrappedValue = allDays.filter(selectedDays.contains).joined()
                        }) {
                            Text(day)
                                .fontWeight(.medium)
                                .foregroundColor(selectedDays.contains(day) ? .white : GlobalColors.darkblue_heading1)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(selectedDays.contains(day) ? GlobalColors.darkorange_highlight2 : GlobalColors.lightorange_highlight3)
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
      
            updateSelectedDaysFromSchedule(selectedDaysString.wrappedValue)
        }
        .onChange(of: selectedDaysString.wrappedValue) { newValue in
            
            updateSelectedDaysFromSchedule(newValue)
        }
        
    }
    
    func updateSelectedDaysFromSchedule(_ schedule: String) {
        selectedDays.removeAll() // Clear the current selection

 
        var mutableSchedule = schedule

       
        let sortedAllDays = allDays.sorted(by: { $0.count > $1.count })

        sortedAllDays.forEach { dayCode in
            if let range = mutableSchedule.range(of: dayCode) {
        
                mutableSchedule.removeSubrange(range)
                selectedDays.insert(dayCode)
            }
        }

     
        
    }

    
    
    func updateSelectedDays(day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }

        viewModel.tempClassDays = selectedDays.sorted(by: { allDays.firstIndex(of: $0)! < allDays.firstIndex(of: $1)! }).joined()
    }
    
    
    
    @ViewBuilder
    private func BlackoutDaysSettingView() -> some View {
        VStack {
            Text("Select Blackout Days")
                .font(GlobalFonts.subHeading(size: 18))
                .foregroundColor(GlobalColors.darkblue_heading1)
                .padding()

            ForEach(DayOfWeek.allCases, id: \.self) { day in
                Toggle(isOn: Binding(
                    get: { self.viewModel.tempBlackoutDays.contains("\(day.rawValue),") },
                    set: { shouldInclude in
                        let dayWithComma = "\(day.rawValue),"
                        if shouldInclude {
                            if !self.viewModel.tempBlackoutDays.contains(dayWithComma) {
                                self.viewModel.tempBlackoutDays.append(dayWithComma)
                            }
                        } else {
                            self.viewModel.tempBlackoutDays = self.viewModel.tempBlackoutDays.replacingOccurrences(of: dayWithComma, with: "")
                        }
                    }
                )) {
                    Text(day.rawValue)
                        .font(GlobalFonts.body(size: 14))
                        .foregroundColor(GlobalColors.lightblue_heading2)
                }
                .toggleStyle(SwitchToggleStyle(tint: GlobalColors.blue_highlight1))
                .padding(.horizontal)
            }

            Button("Confirm Blackout Days") {
                viewModel.setUserBlackoutDays(blackoutDays: viewModel.tempBlackoutDays)
            }
            .buttonStyle(FilledButton())
            .disabled(viewModel.tempBlackoutDays.isEmpty || viewModel.tempClassDays.isEmpty)
            .padding(.top)


        }
        .padding()
       
        .cornerRadius(15)
        .shadow(radius: 10)
    }

    private func fetchUserName() {
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        
        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                self.userName = user.name ?? "User"
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    
    
    struct AssignmentCardView: View {
        let assignment: ScheduleAssignment
        
        var body: some View {
            VStack(alignment: .leading) {
                //ignore warning
                Text(assignment.assignmentName)
                    .font(.headline)
                ForEach(assignment.studyTimes, id: \.self) { time in
                    Text("\(time.day): \(time.time)")
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 4)
            .padding(.horizontal)
        }
    }
    
}


struct FilledButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.white)
            .background(LinearGradient(gradient: Gradient(colors: [GlobalColors.lightblue_heading2, GlobalColors.darkblue_heading1]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut, value: configuration.isPressed)
    }
}


func convertToReadableTime(_ isoDate: String) -> String {
    if isoDate == "0001-01-01T00:00:00Z" {
        return "N/A"
    }
    
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: isoDate) {
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    return "Invalid Time"
}


enum DayOfWeek: String, CaseIterable {
    case monday = "M"
    case tuesday = "T"
    case wednesday = "W"
    case thursday = "Th"
    case friday = "F"
    case saturday = "S"
    case sunday = "SUN"
}



struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
            
            Text("Loading, may take a minute")
                .font(.headline)
                .padding(.top, 20)
            
            Spacer()
        }
        .frame(minHeight: 200)
        .padding()
    }
}
struct MagneticViewWrapper: UIViewRepresentable {
    var enrollments: [Enrollment]
    var size: CGSize
    var onNodeTap: (Enrollment) -> Void
    
    func makeUIView(context: Context) -> MagneticView {
        let magneticView = MagneticView(frame: CGRect(origin: .zero, size: size))
        magneticView.magnetic.backgroundColor = UIColor.clear
        magneticView.backgroundColor = UIColor.clear
        magneticView.magnetic.magneticDelegate = context.coordinator
       
        magneticView.magnetic.magneticField.strength = 1000
        magneticView.magnetic.magneticField.isEnabled = true
        magneticView.magnetic.magneticField.categoryBitMask = 1
        magneticView.magnetic.magneticField.position = CGPoint(x: size.width / 2, y: size.height / 2)
        return magneticView
    }
    
    func updateUIView(_ uiView: MagneticView, context: Context) {
        uiView.frame = CGRect(origin: .zero, size: size)
        
        let existingNodes = uiView.magnetic.children.compactMap { $0 as? Node }
        
        for enrollment in enrollments {
    
            if !existingNodes.contains(where: { $0.representedObject as? Enrollment == enrollment }) {
                let node = Node(text: enrollment.name, image: nil, color: UIColor(GlobalColors.lightorange_highlight3), radius: 85)
                node.label.fontSize = 12
                
                node.label.fontColor = UIColor(GlobalColors.darkblue_heading1)
                node.representedObject = enrollment
                node.physicsBody = SKPhysicsBody(circleOfRadius: 85)
                node.physicsBody?.isDynamic = true
                node.physicsBody?.affectedByGravity = false
                node.physicsBody?.categoryBitMask = 1
                node.physicsBody?.fieldBitMask = 1
                node.physicsBody?.allowsRotation = false
                uiView.magnetic.addChild(node)
            }
        }
        
        
        for node in existingNodes {
            if let nodeEnrollment = node.representedObject as? Enrollment,
               !enrollments.contains(where: { $0 == nodeEnrollment }) {
                node.removeFromParent()
            }
        }
        
        
        uiView.magnetic.magneticField.minimumRadius = 500
        uiView.magnetic.magneticField.strength = 15
        
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onNodeTap: onNodeTap)
    }
    
    class Coordinator: NSObject, MagneticDelegate {
        var parent: MagneticViewWrapper
        var onNodeTap: (Enrollment) -> Void
        var isSetupDone = false
        
        init(_ parent: MagneticViewWrapper, onNodeTap: @escaping (Enrollment) -> Void) {
            self.parent = parent
            self.onNodeTap = onNodeTap
        }
        
        func magnetic(_ magnetic: Magnetic, didSelect node: Node) {
            if let enrollment = node.representedObject as? Enrollment {
                onNodeTap(enrollment)
            }
        }
        
        func magnetic(_ magnetic: Magnetic, didDeselect node: Node) {
           
        }
    }
}

extension Node {
    private struct AssociatedKeys {
        static var representedObject = "representedObject"
    }
    
    //ignore warnings
    var representedObject: Any? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.representedObject) as Any?
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.representedObject,
                    newValue as AnyObject,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
}

