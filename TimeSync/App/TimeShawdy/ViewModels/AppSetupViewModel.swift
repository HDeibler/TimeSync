



import Foundation
import CoreData
import SwiftUI

class AppSetupViewModel: ObservableObject {
    @Published var setupSteps: [SetupStep]
    @Published var apiKey: String = ""
    @Published var priority = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var enrollments: [Enrollment] = []
    @Published var courses: [CourseDetail] = []
    @Published var tempClassDays: String = ""
    @Published var tempClassTimeStart: String = ""
    @Published var tempClassTimeEnd: String = ""
    @Published var selectedCourseIndex: Int? = 0
    @Published var tempBlackoutDays: String = ""
    @Published var studySchedule: [ScheduleAssignment] = []
    @Published var prioritizationQueue: [(courseId: Int, importance: Int)] = []
    
    
    
    init() {
        
        let apiKeyStep = SetupStep(
            title: "API Key Setup",
            instruction: "Please enter your Canvas API key to get started.",
            action: nil
        )
        let setCoursePriority = SetupStep(
            title: "Course Priority",
            instruction: "Which class is most important to your future?",
            action: nil
        )
        
        let setCourseTime = SetupStep(
            title: "Class Schedule",
            instruction: "Please Confirm or Add Class Schedules",
            action: nil
        )
        
        let setBlackOutDays = SetupStep(
            title: "Days you Don't Study",
            instruction: "Please Enter Non Studying Days",
            action: nil
            
        )
        
        self.setupSteps = [apiKeyStep, setCoursePriority, setCourseTime, setBlackOutDays]
        
        
        assignActionsToSteps()
    }
    
    private func assignActionsToSteps() {
        self.setupSteps[0].action = { [weak self] in
            self?.verifyApiKey()
        }
        self.setupSteps[1].action = { [weak self] in
            self?.loadEnrollments()
        }
        self.setupSteps[2].action = { [weak self] in
            self?.fetchCourseDetailsForEnrollments()
        }
        
        
    }
    
    private func clearExistingUserData() {
        CoreDataManager.shared.clearExistingUserData(entityNames: ["User", "EnrollmentEntity", "Assignments"])
    }

    
    private func verifyApiKey() {
        
        clearExistingUserData()
        self.isLoading = true
        APIService.shared.verifyAPIKey(apiKey: self.apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let userModel):
             
                    UserDefaults.standard.set(userModel.id, forKey: "UserID")
                    UserDefaultsManager.saveApiKey(self!.apiKey)
                    CoreDataManager.shared.saveOrUpdateUser(userId: userModel.id, userName: userModel.name, accessKey: userModel.accessKey, blackoutDays: userModel.blackoutDays)
                    self?.completeCurrentStep()
                case .failure(let error):
                    self?.errorMessage = "Verification failed: \(error.localizedDescription)"
                }
            }
        }
    }

    
    func removeDuplicateEnrollments() {
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnrollmentEntity")
        
        do {
            let results = try context.fetch(fetchRequest) as? [NSManagedObject]
            var uniqueIds = Set<String>()
            
            results?.forEach { enrollment in
                if let userId = enrollment.value(forKey: "userId") as? Int64,
                   let courseId = enrollment.value(forKey: "courseId") as? Int64 {
                    let identifier = "\(userId)-\(courseId)"
                    
                    if uniqueIds.contains(identifier) {
                        
                        context.delete(enrollment)
                    } else {
                        uniqueIds.insert(identifier)
                    }
                }
            }
            
            try context.save()
        } catch let error as NSError {
            print("Could not fetch or delete objects: \(error), \(error.userInfo)")
        }
    }
    

    func batchPrioritizeEnrollments() {
        guard let userId = UserDefaults.standard.value(forKey: "UserID") as? Int else { return }

        isLoading = true
        APIService.shared.batchPrioritizeEnrollments(userId: userId, prioritizations: prioritizationQueue) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.completeCurrentStep()
                
                    self?.prioritizationQueue.removeAll()
                case .failure(let error):
                    self?.errorMessage = "Failed to batch prioritize enrollments: \(error.localizedDescription)"
                }
            }
        }
    }


    
 

    
    func removeEnrollment(at index: Int) {
        guard enrollments.indices.contains(index) else { return }
        let enrollment = enrollments[index]
        prioritizationQueue.append((enrollment.courseId, prioritizationQueue.count + 1))
        

        enrollments.remove(at: index)
        
    
        print("Enrollment removed. Updated enrollments and priorities:")
        for (index, enrollment) in enrollments.enumerated() {
            print("\(index + 1): \(enrollment.name), Priority: \(enrollment.prioritized)")
        }



        // Check if all enrollments have been removed
        if enrollments.isEmpty {
            batchPrioritizeEnrollments()
        }
    }
    
    func completeCurrentStep() {
        if let currentStepIndex = setupSteps.firstIndex(where: { !$0.isCompleted }) {
            setupSteps[currentStepIndex].isCompleted = true

            let nextStepIndex = currentStepIndex + 1
            if setupSteps.indices.contains(nextStepIndex) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.setupSteps[nextStepIndex].action?()
                }
            } else {
                // No more steps, mark setup as complete
                UserDefaultsManager.isSetupComplete = true
            }
        } else {
 
            UserDefaultsManager.isSetupComplete = true
        }
    }

    
    private func loadEnrollments() {
        guard let userId = UserDefaults.standard.integer(forKey: "UserID") as? Int else { return }
        APIService.shared.fetchEnrollmentsAndAssignments(forUserId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedEnrollments):
                    self?.enrollments = fetchedEnrollments
                    CoreDataManager.shared.saveEnrollments(fetchedEnrollments)
                    
                case .failure(let error):
                    print("Failed to fetch enrollments: \(error)")
                }
            }
        }

    }
    
    func fetchCourseDetailsForEnrollments() {
        loadStoredEnrollments()
        for enrollment in enrollments {
            APIService.shared.fetchCourseDetails(courseId: enrollment.courseId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let courseDetail):
                        
                        self?.courses.append(courseDetail)
                    case .failure(let error):
                        print("Error fetching course details: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func loadStoredEnrollments() {
        self.enrollments = CoreDataManager.shared.fetchEnrollments().map { storedEnrollment in
            Enrollment(
                userId: Int(storedEnrollment.userId),
                courseId: Int(storedEnrollment.courseId),
                computedCurrentScore: storedEnrollment.computedCurrentScore,
                name: storedEnrollment.name ?? "", assignments: [],
                prioritized: Int(storedEnrollment.prioritized),
                shouldDisplay: true
            )
        }
        

    }
    
    
    func startUpdatingCourses() {
        selectedCourseIndex = nil
        selectNextCourseForUpdate()
    }
    
    
    

    
    func extractTime(from dateTimeString: String) -> String {
        guard dateTimeString.count >= 16 else { return "" }
        
        let startIndex = dateTimeString.index(dateTimeString.startIndex, offsetBy: 11)
        let endIndex = dateTimeString.index(startIndex, offsetBy: 5)
        let extractedTime = String(dateTimeString[startIndex..<endIndex])
        
        
        return extractedTime
    }
    
    
    func selectNextCourseForUpdate() {
        
        let nextIndex: Int? = {
            if let currentIndex = selectedCourseIndex, currentIndex + 1 < courses.count {
                return currentIndex + 1
            } else {
                return courses.firstIndex(where: { !$0.reviewed })
            }
        }()
        
        if let nextIndex = nextIndex {
            selectedCourseIndex = nextIndex
            let nextCourse = courses[nextIndex]
            
            
            tempClassDays = nextCourse.classDays
            tempClassTimeStart = extractTime(from: nextCourse.classTimeStart)
            tempClassTimeEnd = extractTime(from: nextCourse.classTimeEnd)
        } else {
            
            selectedCourseIndex = nil
            
            completeCurrentStep()
        }
    }
    
    
    func updateCourse(courseId: Int, newClassDays: String, newClassTimeStart: String, newClassTimeEnd: String) {
        
        guard let index = courses.firstIndex(where: { $0.id == courseId }) else { return }
        
        let formattedTime = "\(newClassTimeStart)-\(newClassTimeEnd)"
        
        APIService.shared.updateCourseTime(courseId: courseId, day: newClassDays, time: formattedTime) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    print("Course time updated successfully in the backend.")
                    self?.courses[index].classDays = newClassDays
                    self?.courses[index].classTimeStart = newClassTimeStart
                    self?.courses[index].classTimeEnd = newClassTimeEnd
                    self?.courses[index].reviewed = true
                    self?.selectNextCourseForUpdate()
                case .failure(let error):
                    print("Failed to update course time in the backend: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to update course time in the backend: \(error.localizedDescription)"
                }
            }
        }
        
        
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<EnrollmentEntity> = EnrollmentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "courseId == %d", courseId)
         
         do {
             let enrollments = try context.fetch(fetchRequest)
             if let enrollment = enrollments.first {
                 // Assuming classTimes is a combination of start and end times separated by a dash.
                 enrollment.classDays = newClassDays
                 enrollment.classTimes = "\(newClassTimeStart)-\(newClassTimeEnd)"
                 try context.save()
             }
         } catch {
             print("Failed to fetch or save enrollment: \(error.localizedDescription)")
         }
    }
    
    
    
    func setUserBlackoutDays(blackoutDays: String) {
        guard let userId = UserDefaults.standard.value(forKey: "UserID") as? Int else {
            self.errorMessage = "User ID not found"
            return
        }
        
        self.isLoading = true
        APIService.shared.setUserBlackoutDays(userId: userId, blackoutDays: blackoutDays) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    print("Blackout days successfully set")
                    CoreDataManager.shared.updateUserBlackoutDays(userId: Int64(userId), blackoutDays: blackoutDays)
                    
                    
                    self?.completeCurrentStep()
                case .failure(let error):
                    self?.errorMessage = "Failed to set blackout days: \(error.localizedDescription)"
                }
            }
        }
    }
    
    
    func fetchStudySchedule(completion: @escaping () -> Void) {
        self.isLoading = true
        guard let userId = UserDefaults.standard.integer(forKey: "UserID") as? Int, userId != 0 else { return }
        
        self.isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
        guard let url = URL(string: "http://ec2-18-119-253-176.us-east-2.compute.amazonaws.com:3000/API/create/schedule/\(userId)/\(formattedDate)") else {
            print("Invalid URL")
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                completion()
                
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
                    self?.studySchedule = scheduleResponse.studySchedule
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}

extension AppSetupViewModel {
    var progressFraction: Double {
        let totalSteps = Double(setupSteps.count)
        
        let currentStepIndex = Double(setupSteps.firstIndex(where: { !$0.isCompleted }) ?? setupSteps.count)
        return currentStepIndex / totalSteps
    }
}


extension AppSetupViewModel {
    func isValidDay(_ day: String) -> Bool {
        
        let validDays = ["M", "T", "W", "Th", "F", "S", "SUN"]
        return validDays.contains(where: day.contains)
    }
    
    func isValidTime(_ time: String) -> Bool {
        let timeRegex = "^([01]?[0-9]|2[0-3]):[0-5][0-9]$"
        return time.range(of: timeRegex, options: .regularExpression) != nil
    }
    
    func formatTimeRange(start: String, end: String) -> String? {
        guard isValidTime(start), isValidTime(end) else { return nil }
        return "\(start)-\(end)"
    }
}


extension AppSetupViewModel {
    func setTemporaryError(message: String, forDuration duration: TimeInterval = 2.0) {
        self.errorMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.errorMessage = nil
        }
    }
}







