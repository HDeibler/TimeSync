package Services

import (
	"Database/API"
	"Database/Models"
	"Database/Services/db"
	"fmt"
	"log"
	"strings"
	"time"
)



func UpdateUser(userID int) {
	user, err := API.GetUser(userID)
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		return
	}


	err = db.InsertUser(user)
	if err != nil {
		log.Printf("Error inserting user into the database: %v", err)
	
	}
}

func GetUserByID(userID int) (Models.User, error) {
    user, err := db.GetUserByID(userID)
    if err != nil {
        log.Printf("Error fetching user with ID %d: %v", userID, err)
        return Models.User{}, err
    }

    return user, nil
}

func GetEnrollmentsByID(userID int) ([]Models.Enrollment, error) {
	
	courses, err := db.GetEnrollmentsByID(userID)
	if err != nil {
		log.Printf("Error fetching courses for user %d: %v", userID, err)
		return nil, err
	}

	return courses, nil
}


func GetAssignmentByCourseID(CourseID int) ([]Models.Assignment, error){
	assignments, err := db.GetAssignmentsByCourseID(CourseID)
	if err != nil {
		log.Printf("Error fetching assignments for course %d: %v", CourseID, err)
		return nil, err
	}
	return assignments, nil
}

func SetEnrollmentPriority(userID int, courseID int, priority int) error {
    if priority < 0 || priority > 9 {
        return fmt.Errorf("invalid priority: %d", priority)
    }
    
    
    err := db.UpdateSpecificEnrollmentPriority(userID, courseID, priority)
    if err != nil {
        log.Printf("Error updating priority for user %d and course %d: %v", userID, courseID, err)
        return fmt.Errorf("error updating specific enrollment priority: %v", err)
    }

    return nil
}


func IsBlackoutDay(blackoutDays string, day time.Weekday) bool {

    daysMap := map[string]time.Weekday{
        "M":    time.Monday,
        "T":    time.Tuesday,
        "W":    time.Wednesday,
        "Th":   time.Thursday,
        "F":    time.Friday,
        "S":    time.Saturday,
        "SUN":  time.Sunday,
    }

    
    days := strings.Split(blackoutDays, ",")
    
    
    for _, d := range days {
        if daysMap[d] == day {
            return true
        }
    }

    return false
}
