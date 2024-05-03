import SwiftUI
import CoreData
import SwiftUI
import CoreData

import SwiftUI
import CoreData

import SwiftUI
import CoreData

struct AssignmentsView: View {
    @State private var assignmentsMap: [EnrollmentEntity: [Assignments]]?
    @State private var selectedAssignment: Assignments?
    @State private var isTimingAssignment = false
    @State private var showTimingView = false

    var body: some View {
        VStack {
            Text("Current Assignments")
                .font(.title)
                .foregroundColor(GlobalColors.darkblue_heading1)
                .padding(.top, -10) // Adjusted top padding
            
            if let assignmentsMap = assignmentsMap {
                if assignmentsMap.isEmpty {
                    Text("No assignments for this week.")
                        .foregroundColor(GlobalColors.darkblue_heading1)
                        .padding()
                } else {
                    List {
                        ForEach(assignmentsMap.flatMap { $0.value }.sorted(by: { assignment1, assignment2 in
                            guard let dueDate1 = convertToDueDate(assignment1.due_at), let dueDate2 = convertToDueDate(assignment2.due_at) else {
                                return false
                            }
                            return dueDate1 < dueDate2
                        }), id: \.self) { assignment in
                            if let dueDate = convertToDueDate(assignment.due_at), isAssignmentForThisWeek(dueDate) {
                                NavigationLink(destination: TimingView(assignment: assignment, onClose: {
                                 
                                    showTimingView = false
                                }), isActive: $showTimingView) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(assignment.name ?? "Unnamed Task")
                                                .font(.headline)
                                                .foregroundColor(GlobalColors.darkblue_heading1)
                                            Text("Due Date: \(formatDueDate(dueDate))")
                                                .font(.subheadline)
                                                .foregroundColor(GlobalColors.lightblue_heading2)
                                            Text("Points: \(assignment.points_possible)")
                                                .font(.subheadline)
                                                .foregroundColor(GlobalColors.lightblue_heading2)
                                        }
                                        .padding(.vertical, 8)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                        Spacer() // Pushes VStack to the left
                                    }
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    selectedAssignment = assignment
                                    showTimingView = true
                                })
                                .id(assignment)
                            }
                        }
                    }
                }
            } else {
                ProgressView("Loading assignments...")
                    .progressViewStyle(CircularProgressViewStyle(tint: GlobalColors.darkorange_highlight2))
                    .foregroundColor(GlobalColors.darkblue_heading1)
                    .padding()
                    .onAppear {
                        fetchUserAssignments()
                    }
            }
        }
        .navigationTitle("Weekly Assignments")
        .background(GlobalColors.lightorange_highlight3.edgesIgnoringSafeArea(.all))
    }

    private func fetchUserAssignments() {
        guard let userId = UserDefaults.standard.value(forKey: "UserID") as? Int64 else { return }
        self.assignmentsMap = CoreDataManager.shared.fetchUserAssignments(userId: userId)
    }

    private func isAssignmentForThisWeek(_ dueDate: Date) -> Bool {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        return dueDate >= startOfWeek && dueDate < endOfWeek
    }

    private func convertToDueDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.date(from: dateString)
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}


struct TimingView: View {
    @State private var elapsedTime: TimeInterval = 0
    private var assignment: Assignments
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var onClose: () -> Void
    
    @State private var isTimingStarted = false
    @State private var isShowingCompletionConfirmation = false

    // Change the access level of the initializer to internal
    init(assignment: Assignments, onClose: @escaping () -> Void) {
        self.assignment = assignment
        self.onClose = onClose
        _elapsedTime = State(initialValue: assignment.time)
    }
    
    var body: some View {
        VStack {
            Text(assignment.name ?? "Unnamed Assignment")
                .font(.title)
                .foregroundColor(GlobalColors.darkblue_heading1)
                .padding()
            
            Text("\(elapsedTime.secondsToHoursMinutesSeconds())")
                .font(.title)
                .foregroundColor(GlobalColors.darkblue_heading1)
                .padding()

            if isTimingStarted {
                Button(action: {
                    isShowingCompletionConfirmation = true
                }) {
                    Text("End Timing")
                        .padding()
                        .background(GlobalColors.darkorange_highlight2)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Button(action: {
                    isTimingStarted = true
                    // Start the timer
                    timer = Timer.publish(every: 1, on: .main, in: .common)
                        .autoconnect()
                }) {
                    Text("Start Timing")
                        .padding()
                        .background(GlobalColors.darkorange_highlight2)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .onReceive(timer) { _ in
            guard isTimingStarted else { return }
            elapsedTime += 1
        }
        .onDisappear {
            if isTimingStarted {
                CoreDataManager.shared.updateAssignmentTime(assignment: assignment, elapsedTime: elapsedTime)
                timer.upstream.connect().cancel() // Cancel the timer
            }
        }

        .alert(isPresented: $isShowingCompletionConfirmation) {
            Alert(
                title: Text("Assignment Completed?"),
                message: Text("Have you completed the assignment?"),
                primaryButton: .default(Text("Yes")) {
                
                    CoreDataManager.shared.updateAssignmentCompletion(assignment: assignment, completed: true)
                    onClose()
                },
                secondaryButton: .cancel(Text("No")) {
                    isTimingStarted = false
                    onClose()
                }
            )
        }
    }
}


extension CoreDataManager {
    func updateAssignmentTime(assignment: Assignments, elapsedTime: TimeInterval) {
        _ = persistentContainer.viewContext
        assignment.time += elapsedTime 
        saveContext()
    }
    
    func updateAssignmentCompletion(assignment: Assignments, completed: Bool) {
        _ = persistentContainer.viewContext
        assignment.completed = completed
        saveContext()
    }
}

extension TimeInterval {
    func secondsToHoursMinutesSeconds() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private func formatDueDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    
    // Check if the due date is in the past
    if date < now {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d" // Format to display month and day
        return dateFormatter.string(from: date)
    }
    
    // Check if the due date is less than a week away
    if let dueDateInAWeek = calendar.date(byAdding: .day, value: 7, to: now), date <= dueDateInAWeek {
        let weekday = calendar.component(.weekday, from: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Format to display the day name
        return dateFormatter.string(from: date)
    } else {
        // If the due date is more than a week away, format it normally
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d" // Format to display month and day
        return dateFormatter.string(from: date)
    }
}
