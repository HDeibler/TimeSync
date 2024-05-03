package Services

import (
	"Database/API"
	"Database/Models"
	"Database/Services/db"
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"
)

func CanvasUpdateCourses() {
    courses, err := API.GetCourses()
    if err != nil {
        log.Printf("Error fetching courses: %v", err)
        return
    }


    for _, course := range courses {

        if course.EnrollmentTermID == 133 {
     
            err := db.InsertCourse(course)
            if err != nil {
                log.Printf("Error inserting course into the database: %v", err)
                continue 
            }

     
            for _, enrollment := range course.Enrollments {
          
                enrollment.CourseID = course.CourseID
                err := db.InsertEnrollment(enrollment)
                if err != nil {
                    log.Printf("Error inserting enrollment for user %d in course %d into the database: %v", enrollment.UserID, course.CourseID, err)
                 
                    continue 
                }
            }
        }
    }
}

func GetCourseByID(courseID int) (Models.Course, error){
    course, err := db.GetCoursesByID(courseID)
    if err != nil {
        log.Printf("Error fetching courses for user %d: %v", courseID, err)
        return Models.Course{}, err 
    }
    
    return course, nil
}


func CanvasGetAssignmentsForUserAndGlobal(userID int) ([]Models.Assignment, error) {
    var allAssignments []Models.Assignment

 
    courses, err := db.GetEnrollmentsByID(userID)
    if err != nil {
        log.Printf("Error fetching courses for user %d: %v", userID, err)
        return nil, err
    }


    for _, course := range courses {
        assignments, err := API.GetAssignmentsByCourseID(course.CourseID)
        if err != nil {
            log.Printf("Error fetching assignments for course %d: %v", course.CourseID, err)
            continue
        }

        for _, assignment := range assignments {
        
            err := db.InsertAssignment(assignment)
            if err != nil {
                log.Printf("Error inserting assignment for course %d into the database: %v", course.CourseID, err)
              
                continue
            }

            allAssignments = append(allAssignments, assignment)
        }
    }

    return allAssignments, nil
}

func UpdateCourseTime(courseID int, day string, timeRange string) error {
    // Validate 'day' is a valid day abbreviation like "MWF" or "TTh"
    if !isValidDay(day) {
        return fmt.Errorf("invalid day format")
    }
    fmt.Println("Time Range")
    fmt.Println(timeRange)
    fmt.Println("Day")
    fmt.Println(day)

    times := strings.Split(timeRange, "-")
    if len(times) != 2 {
        return fmt.Errorf("invalid time range format")
    }

    startTimeStr, endTimeStr := times[0], times[1]

    if !isValidTime(startTimeStr) {
        return fmt.Errorf("invalid start time format")
    }

 
    if !isValidTime(endTimeStr) {
        return fmt.Errorf("invalid end time format")
    }

    return db.UpdateCourseTime(courseID, day, startTimeStr, endTimeStr)
}

func isValidDay(day string) bool {
    match, _ := regexp.MatchString("^(M|T|W|Th|F|S|SUN)+$", day)
    return match
}


func isValidTime(timeStr string) bool {
    match, _ := regexp.MatchString("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", timeStr)
    return match
}


func parseTime(timeStr string) (time.Time, error) {
    if !isValidTime(timeStr) {
        return time.Time{}, fmt.Errorf("invalid time format")
    }
    return time.Parse("15:04", timeStr)
}










