import SwiftUI
import CoreData

struct WelcomeView: View {
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.trailing, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome, User!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(GlobalColors.darkorange_highlight2)
                
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

struct DashboardView: View {
    @State private var user: User?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                WelcomeView() // Added Welcome block
                
                HStack {
                    SummaryCard(title: "Weekly Assignments", value: "\(totalAssignmentsThisWeek())", color: GlobalColors.darkorange_highlight2)
                }
                .padding(20)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Weekly Progress")
                        .font(.title)
                        .foregroundColor(GlobalColors.darkorange_highlight2) // Updated color
                        .padding(.horizontal, 15)
                        .padding(.top, 15)
                    
                    ProgressBar(value: .constant(0.75), color: GlobalColors.darkorange_highlight2).padding(20)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Courses")
                        .font(.title)
                        .foregroundColor(GlobalColors.darkorange_highlight2) // Updated color
                        .padding(.top, 20)
                    
                    if let enrollments = user?.enrollments as? Set<EnrollmentEntity> {
                        ForEach(Array(enrollments).sorted(by: { $0.prioritized < $1.prioritized }), id: \.self) { enrollment in
                            let assignmentsArray = (enrollment.assignments?.allObjects as? [Assignments]) ?? []
                            
                            let assignmentsThisWeek = assignmentsArray.compactMap { assignment -> Date? in
                                guard let dueAtString = assignment.due_at else { return nil }
                                return convertToDueDate(dueAtString)
                            }.filter { dueDate in
                                isAssignmentForThisWeek(dueDate)
                            }.count
                            
                            let times = "\(enrollment.classTimes ?? "N/A") \(enrollment.classDays ?? "")"
                            
                            ClassBlockView(
                                className: enrollment.name ?? "N/A",
                                times: times,
                                assignmentsThisWeek: assignmentsThisWeek,
                                backgroundColor: backgroundColor(forPriority: enrollment.prioritized),
                                priority: Int(enrollment.prioritized)
                            )
                        }
                    } else {
                        Text("No user data available")
                            .padding()
                    }
                    Spacer()
                }
                .padding()
            }
            .padding(.top, -30)
        }
        .onAppear {
            self.user = CoreDataManager.shared.fetchCompleteUser()
        }
    }
    
    private func isAssignmentForThisWeek(_ dueDate: Date) -> Bool {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)!
        return dueDate >= startOfWeek && dueDate < endOfWeek
    }
    
    private func totalAssignmentsThisWeek() -> Int {
        guard let enrollments = user?.enrollments as? Set<EnrollmentEntity> else {
            return 0
        }

        return enrollments.reduce(0) { partialResult, enrollment in
            let assignmentsArray = (enrollment.assignments?.allObjects as? [Assignments]) ?? []
            let assignmentsThisWeek = assignmentsArray.compactMap { assignment -> Date? in
                guard let dueAtString = assignment.due_at else { return nil }
                return convertToDueDate(dueAtString)
            }.filter { dueDate in
                isAssignmentForThisWeek(dueDate)
            }.count
            
            return partialResult + assignmentsThisWeek
        }
    }
}

private func backgroundColor(forPriority priority: Int64) -> Color {
    switch priority {
    case 1:
        return GlobalColors.lightorange_highlight3
    case 2:
        return GlobalColors.blue_highlight1
    case 3:
        return GlobalColors.darkorange_highlight2
    case 4:
        return GlobalColors.lightorange_highlight3
    case 5:
        return GlobalColors.lightorange_highlight3
    case 6:
        return GlobalColors.lightorange_highlight3
    case 7:
        return GlobalColors.lightorange_highlight3
    default:
        return GlobalColors.blue_highlight1
    }
}

struct SummaryCard: View {
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(GlobalFonts.subHeading(size: 16))
                .foregroundColor(GlobalColors.darkblue_heading1)
            Text(value)
                .font(GlobalFonts.mainHeading(size: 22))
                .foregroundColor(color)
        }
        .padding()
        .background(GlobalColors.blue_highlight1.opacity(0.3))
        .cornerRadius(10)
    }
}

struct ProgressBar: View {
    @Binding var value: Float
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: 20)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.systemTeal))
                
                Rectangle().frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: 20)
                    .foregroundColor(color)
                    .animation(.linear, value: value)
            }.cornerRadius(45.0)
        }
    }
}

struct TaskRow: View {
    var taskName: String
    var dueDate: String
    var color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(taskName)
                    .font(GlobalFonts.body(size: 14))
                    .foregroundColor(GlobalColors.darkblue_heading1)
                Text(dueDate)
                    .font(GlobalFonts.body(size: 12))
                    .foregroundColor(GlobalColors.lightblue_heading2)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.3))
        .cornerRadius(8)
    }
}
