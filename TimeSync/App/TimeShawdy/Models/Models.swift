//
//  Models.swift
//  TimeShawdy
//
//  Created by Andrew on 2/1/24.
//

import Foundation




import Foundation

// UserModel.swift
struct UserModel: Codable {
    let id: Int
    let name: String
    let accessKey: String
    let blackoutDays: String?
    let parsedBlackoutDays: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, accessKey, blackoutDays
        case parsedBlackoutDays = "parsedblackoutDays"
    }
}
        
    


// EnrollmentModel.swift
struct Enrollment: Codable, Identifiable, Equatable {
    let id = UUID()
    let userId: Int
    let courseId: Int
    let computedCurrentScore: Double
    let name: String
    let assignments: [Assignment]?
    var prioritized: Int
    var shouldDisplay: Bool = true

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case courseId = "course_id"
        case computedCurrentScore = "computed_current_score"
        case name, assignments, prioritized
        
    }
    
    static func ==(lhs: Enrollment, rhs: Enrollment) -> Bool {
           return lhs.id == rhs.id
       }
}

struct Assignment : Codable, Identifiable, Hashable {
    var id: Int
    var due_at: String
    var points_possible: Double
    var course_id: Int
    var name: String
    var description: String
}



struct CourseDetail: Codable, Identifiable {
    var id: Int
    var name: String
    var enrollmentTermId: Int
    var classDays: String
    var classTimeStart: String
    var classTimeEnd: String
    var reviewed: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, name, enrollmentTermId = "enrollment_term_id", classDays = "class_days", classTimeStart = "class_time_start", classTimeEnd = "class_time_end"
     
    }
}

struct StudyScheduleResponse: Decodable {
    let studySchedule: [ScheduleAssignment]
}

struct ScheduleAssignment: Decodable, Identifiable {
    var id = UUID()
    let assignmentName: String
    let studyTimes: [StudyTime]
    
    enum CodingKeys: String, CodingKey {
        case assignmentName
        case studyTimes
    }
}

struct StudyTime: Decodable, Hashable {
    let day: String
    let time: String
}




