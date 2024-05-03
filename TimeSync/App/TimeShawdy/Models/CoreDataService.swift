import CoreData
import SwiftUI
import Combine

class CoreDataManager {
    static let shared = CoreDataManager()
    var eventsDidChange = PassthroughSubject<Void, Never>()

    let persistentContainer: NSPersistentContainer
    
    
    init() {
        persistentContainer = NSPersistentContainer(name: "Model")
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
 
    
    func saveEnrollments(_ enrollments: [Enrollment]) {
        let context = persistentContainer.viewContext
        guard let userId = UserDefaults.standard.integer(forKey: "UserID") as? Int, userId != 0 else { return }
        
        let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "userId == %lld", userId)
        
        guard let user = (try? context.fetch(userFetchRequest).first) else {
            print("User not found, can't save enrollments")
            return
        }
        
        context.perform {
            for enrollmentData in enrollments {
                let enrollmentFetchRequest: NSFetchRequest<EnrollmentEntity> = EnrollmentEntity.fetchRequest()
                enrollmentFetchRequest.predicate = NSPredicate(format: "courseId == %lld AND user == %@", Int64(enrollmentData.courseId), user)
                
                let enrollmentEntity = (try? context.fetch(enrollmentFetchRequest).first) ?? EnrollmentEntity(context: context)
                enrollmentEntity.user = user
                
                
                // Update enrollment properties
                enrollmentEntity.userId = Int64(enrollmentData.userId)
                enrollmentEntity.courseId = Int64(enrollmentData.courseId)
                enrollmentEntity.computedCurrentScore = enrollmentData.computedCurrentScore
                enrollmentEntity.name = enrollmentData.name
                enrollmentEntity.prioritized = Int64(enrollmentData.prioritized)
                
                // Update or create new assignments
                if let assignmentDataArray = enrollmentData.assignments {
                    // First, remove old assignments if needed
                    if let existingAssignments = enrollmentEntity.assignments as? Set<Assignments>, !existingAssignments.isEmpty {
                        existingAssignments.forEach(context.delete)
                    }
                    // Now, add the new/updated assignments
                    
                    
                    for assignmentData in assignmentDataArray {
                        let assignmentEntity = Assignments(context: context)
                        assignmentEntity.assignmentId = Int64(assignmentData.id)
                        assignmentEntity.due_at = assignmentData.due_at
                        assignmentEntity.points_possible = Double(assignmentData.points_possible)
                        assignmentEntity.course_Id = Int64(assignmentData.course_id)
                        assignmentEntity.name = assignmentData.name
                        assignmentEntity.desc = assignmentData.description
                        enrollmentEntity.addToAssignments(assignmentEntity)
                    }
                }
            }
            
         
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    
    func fetchEnrollments() -> [EnrollmentEntity] {
        let fetchRequest: NSFetchRequest<EnrollmentEntity> = EnrollmentEntity.fetchRequest()
        
        do {
            return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch enrollments: \(error), \(error.userInfo)")
            return []
        }
    }
    
    
    func clearExistingUserData(entityNames: [String]) {
        let context = persistentContainer.viewContext
        entityNames.forEach { entityName in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to clear \(entityName): \(error)")
            }
        }
        
        saveContext()
    }
    
    func saveOrUpdateUser(userId: Int, userName: String, accessKey: String, blackoutDays: String?) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %d", userId)
        
        do {
            let results = try context.fetch(fetchRequest)
            let user: User
            if let existingUser = results.first {
                existingUser.name = userName
                user = existingUser
            } else {
                let newUser = User(context: context)
                newUser.userId = Int64(userId)
                newUser.name = userName
                user = newUser
            }
            user.accessKey = accessKey
            user.blackoutDays = blackoutDays ?? ""
            
            saveContext()
        } catch {
            fatalError("Failed to save or update user: \(error)")
        }
    }
    
    func removeDuplicateEnrollments() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnrollmentEntity")
        
        do {
            let results = try context.fetch(fetchRequest) as? [EnrollmentEntity]
            var uniqueIds = Set<String>()
            
            results?.forEach { enrollment in
                let identifier = "\(enrollment.userId)-\(enrollment.courseId)"
                if uniqueIds.contains(identifier) {
                    context.delete(enrollment)
                } else {
                    uniqueIds.insert(identifier)
                }
            }
            
            saveContext()
        } catch let error as NSError {
            fatalError("Could not fetch or delete objects: \(error), \(error.userInfo)")
        }
    }
    
    
    func updateEnrollmentPriority(userId: Int64, courseId: Int64, priority: Int64) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<EnrollmentEntity> = EnrollmentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %lld AND courseId == %lld", userId, courseId)
        
        do {
            let enrollments = try context.fetch(fetchRequest)
            if let enrollment = enrollments.first {
                enrollment.prioritized = priority
                saveContext()
                print("Priority updated for enrollment: User ID \(userId), Course ID \(courseId).")
            } else {
                print("Enrollment not found.")
            }
        } catch let error as NSError {
            print("Could not fetch or update enrollment priority: \(error), \(error.userInfo)")
        }
    }
    
    
    func updateUserBlackoutDays(userId: Int64, blackoutDays: String) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %lld", userId)
        
        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                user.blackoutDays = blackoutDays
                saveContext()
                print("Blackout days updated for user ID \(userId).")
            } else {
                print("User not found.")
            }
        } catch let error as NSError {
            print("Could not fetch or update user's blackout days: \(error), \(error.userInfo)")
        }
    }
    
    
    func printUserEnrollments(userId: Int64) {
        let context = self.persistentContainer.viewContext
        let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "userId == %lld", userId)
        
        do {
            let users = try context.fetch(userFetchRequest)
            if users.isEmpty {
                print("No user found for ID: \(userId)")
                return
            }
            
            for user in users {
                print("\n--- Enrollments for User ID: \(user.userId), Name: \(user.name ?? "Unknown") ---")
                guard let enrollments = user.enrollments as? Set<EnrollmentEntity>, !enrollments.isEmpty else {
                    print("No enrollments found for User ID: \(user.userId)")
                    continue
                }
                
                for enrollment in enrollments.sorted(by: { $0.courseId < $1.courseId }) {
                    print("Course ID: \(enrollment.courseId), Name: \(enrollment.name ?? "Unknown"), Priority: \(enrollment.prioritized), Score: \(enrollment.computedCurrentScore)")
                }
            }
        } catch {
            print("Error fetching or printing user's enrollments: \(error)")
        }
    }
    
    
    func fetchUserAssignments(userId: Int64) -> [EnrollmentEntity: [Assignments]] {
        let context = self.persistentContainer.viewContext
        let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "userId == %lld", userId)

        var enrollmentsWithAssignments: [EnrollmentEntity: [Assignments]] = [:]

        do {
            if let user = try context.fetch(userFetchRequest).first {
                for enrollment in user.enrollments as? Set<EnrollmentEntity> ?? [] {
                    let assignments = enrollment.assignments as? Set<Assignments> ?? []
                    enrollmentsWithAssignments[enrollment] = Array(assignments)
                }
                return enrollmentsWithAssignments
            } else {
                print("No user found for ID: \(userId)")
                return enrollmentsWithAssignments
            }
        } catch {
            print("Error fetching user's assignments: \(error)")
            return enrollmentsWithAssignments
        }
    }
    
    
    func fetchCompleteUser() -> User? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1 // Ensure only one User object is fetched
        fetchRequest.relationshipKeyPathsForPrefetching = ["enrollments", "enrollments.assignments"]
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch let error as NSError {
            print("Could not fetch the user: \(error), \(error.userInfo)")
            return nil
        }
    }
    
    
    func updateEnrollmentsAndAssignments(forUserId userId: Int) {
        APIService.shared.fetchEnrollmentsAndAssignments(forUserId: userId) { [weak self] result in
            switch result {
            case .success(let enrollments):
                self?.saveEnrollments(enrollments)
                
            case .failure(let error):
                print(error)
            }
        }
    }
}



extension CoreDataManager {
    
    // Fetch all events for a specific date
    func fetchEvents(for date: Date) -> [CalendarEvent] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<CalendarEvent> = CalendarEvent.fetchRequest()
        
      
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "(date >= %@) AND (date < %@)", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch events for date \(date): \(error)")
            return []
        }
    }
    
    // Add a new event
    func addEvent(title: String, date: Date, startTime: String, endTime: String, isFromChatGPT: Bool) {
        let context = persistentContainer.viewContext
        let newEvent = CalendarEvent(context: context)
        
        // Assign a new UUID
        newEvent.id = UUID()
        
        newEvent.title = title
        newEvent.date = date
        newEvent.startTime = startTime
        newEvent.endTime = endTime
        newEvent.isFromChatGPT = isFromChatGPT
        
        saveContext()
        
        // Notify subscribers that events data has changed
        eventsDidChange.send()
    }
    // Delete an event
    func deleteEvent(_ event: CalendarEvent) {
        let context = persistentContainer.viewContext
        context.delete(event)
        saveContext()
    }
    
    // Update an existing event
    func updateEvent(_ event: CalendarEvent, withTitle title: String, date: Date, startTime: String, endTime: String, isFromChatGPT: Bool) {
        event.title = title
        event.date = date
        event.startTime = startTime
        event.endTime = endTime
        event.isFromChatGPT = isFromChatGPT
        saveContext()
    }
    
    
    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<CalendarEvent> = CalendarEvent.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)", startDate as NSDate, endDate as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch events from \(startDate) to \(endDate): \(error)")
            return []
        }
    }
    
    func fetchAllCalendarEvents() -> [CalendarEvent] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<CalendarEvent> = CalendarEvent.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching calendar events: \(error)")
            return []
        }
    }
    
    
    func fetchStudySchedule(){
        let context = self.persistentContainer.viewContext
        guard let userId = UserDefaults.standard.value(forKey: "UserID") as? Int, userId != 0 else { return }
        
        // Clear existing CalendarEvent data
        self.clearCalendarEvents()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
        guard let url = URL(string: "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/API/create/schedule/\(userId)/\(formattedDate)") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching study schedule: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Unexpected response status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    let scheduleResponse = try JSONDecoder().decode(StudyScheduleResponse.self, from: data)
                    for assignment in scheduleResponse.studySchedule {
                        for studyTime in assignment.studyTimes {
                            self.addEventFromSchedule(assignmentName: assignment.assignmentName, studyTime: studyTime, context: context)
                        }
                    }
                } catch {
                    print("Decoding error: \(error)")
                }
                
            }
        }.resume()
    }

    
    func addEventFromSchedule(assignmentName: String, studyTime: StudyTime, context: NSManagedObjectContext) {
          
          let newEvent = CalendarEvent(context: context)
          newEvent.id = UUID()
          newEvent.title = assignmentName
          newEvent.isFromChatGPT = true
          
         
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          if let date = dateFormatter.date(from: studyTime.day) {
              newEvent.date = date // Set the date of the event
          } else {
              print("Error parsing date from string: \(studyTime.day)")
          }
          
          // Split the time string and format start and end times
          let times = studyTime.time.split(separator: "-").map(String.init)
          if times.count == 2 {
              newEvent.startTime = formatTime(times[0].trimmingCharacters(in: .whitespaces))
              newEvent.endTime = formatTime(times[1].trimmingCharacters(in: .whitespaces))
          }
          
          // Attempt to save the new event to the context
          do {
              try context.save()
          } catch {
              print("Failed to save event from ChatGPT: \(error.localizedDescription)")
          }
      }
      
      // Helper method to convert 24-hour time to 12-hour time with AM/PM
      private func formatTime(_ time: String) -> String {
          let timeFormatter = DateFormatter()
          timeFormatter.dateFormat = "HH:mm"
          if let date = timeFormatter.date(from: time) {
              timeFormatter.dateFormat = "h:mm a"
              return timeFormatter.string(from: date)
          } else {
              print("Error formatting time: \(time)")
              return time
          }
      }
    
    func clearCalendarEvents() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CalendarEvent.fetchRequest()
        
        // Check if there are any CalendarEvent objects to delete
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                print("No CalendarEvent data to clear.")
                return // Exit if no objects to delete
            }
        } catch let error as NSError {
            print("Error checking CalendarEvent data count: \(error), \(error.userInfo)")
            return
        }

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs // To get the list of deleted objectIDs

        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [context])
            saveContext()
            print("Successfully cleared CalendarEvent data.")
        } catch let error as NSError {
            print("Error clearing CalendarEvent data: \(error), \(error.userInfo)")
        }
    }
    
    
 

    func toggleEventCompleted(eventID: UUID) {
        // Fetch the event by ID, toggle its completion, and save the context
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<CalendarEvent> = CalendarEvent.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)

        do {
            if let event = try context.fetch(fetchRequest).first {
                event.completed.toggle()
                try context.save()
                eventsDidChange.send() // Notify subscribers
            }
        } catch {
            print("Error toggling event completion: \(error)")
        }
    }
    
    
    
    
}

