package Models

import "time"

type User struct {
	ID           int      `json:"id"`
	Name         string   `json:"name"`
	AccessKey    string   `json:"accessKey"`
	BlackoutDays  string `json:"blackoutDays"`
	UserBlackoutDays []string `json:"parsedblackoutDays"`

} 


type Course struct {
    CourseID             int         	`json:"id"`
    Name                 string    	  	`json:"name"`
    EnrollmentTermID     int       	  	`json:"enrollment_term_id"`
    UserID               int         	`json:"user_id"` 
    ComputedCurrentScore float64     	`json:"computed_current_score"` 
    Enrollments          []Enrollment 	`json:"enrollments"`
	ClassDays		     string			`json:"class_days"`
	ClassTimeStart		 time.Time		`json:"class_time_start"`
	ClassTimeEnd		 time.Time		`json:"class_time_end"`
}

type Enrollment struct {
    UserID               int          `json:"user_id"`
    CourseID             int          `json:"course_id"`
    ComputedCurrentScore float64      `json:"computed_current_score"`
    Name                 string       `json:"name"`
    Assignments          []Assignment `json:"assignments"` 
    Prioritize           int          `json:"prioritized"`
}

type Assignment struct {
    AssignmentID   int       `json:"id"`
    DueAt          time.Time  `json:"due_at"`
	DueAtFormatted string    `json:"due_at_formatted,omitempty"` // For prompt
    PointsPossible float64   `json:"points_possible"`
    CourseID       int       `json:"course_id"`
    Name           string    `json:"name"`
    Description    string    `json:"description"`
}

type SimplifiedAssignment struct {
    DueAt          string  `json:"dueAt"`
    PointsPossible float64 `json:"pointsPossible"`
    Name           string  `json:"name"`
}

// SimplifiedEnrollment includes the course name, a readable prioritization, and simplified assignments
type SimplifiedEnrollment struct {
    CourseName    string                `json:"courseName"`
    Prioritization string               `json:"prioritization"`
    Assignments   []SimplifiedAssignment `json:"assignments"`
}




// ScheduleEvent represents a scheduled event that occupies a user's time.
type ScheduleEvent struct {
	Day   []string `json:"day"`
	Time  string `json:"time"`
	Event string `json:"event"`
}


// StudyTime represents a study time slot for an assignment.
type StudyTime struct {
	Day string `json:"day"`
	Time string `json:"time"`
}

// StudyScheduleItem represents an entry in the study schedule, corresponding to an assignment.
type StudyScheduleItem struct {
	AssignmentName string      `json:"assignmentName"`
	StudyTimes     []StudyTime `json:"studyTimes"`
}

// StudySchedule represents the complete study schedule.
type StudySchedule []StudyScheduleItem

// Prompt represents the input data for generating a study schedule.
type Prompt struct {
    CurrentDay         time.Time          `json:"currentDay"`
    CurrentSchedule    []ScheduleEvent    `json:"currentSchedule"`
    StudyBlackoutDays  []string           `json:"studyBlackoutDays"`
    SimplifiedEnrollments []SimplifiedEnrollment `json:"enrollments"`
}
// Completion represents the output study schedule.
type Completion struct {
	StudySchedule StudySchedule `json:"studySchedule"`
}

// FullPromptCompletionModel represents the full model including both prompt and completion.
type FullPromptCompletionModel struct {
	Prompt     Prompt     `json:"prompt"`
	Completion Completion `json:"completion"`
}
