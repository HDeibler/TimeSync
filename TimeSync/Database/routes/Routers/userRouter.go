package Router

import (
	"Database/Models"
	"Database/Services"
	"Database/Services/db"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)




func HandleCoursesRequest(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }

    courses, err := Services.GetEnrollmentsByID(userID)
    if err != nil {
        http.Error(w, "Error fetching courses", http.StatusInternalServerError)
        log.Printf("Error fetching courses for user %d: %v", userID, err)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(courses)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding courses to JSON: %v", err)
    }
}



func HandleUserRequest(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }

    user, err := Services.GetUserByID(userID)
    if err != nil {
        http.Error(w, "Error fetching user", http.StatusInternalServerError)
        log.Printf("Error fetching user with ID %d: %v", userID, err)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(user)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding user to JSON: %v", err)
    }
}

func GetAssignmentsRequest(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }

    enrollments, err := Services.GetEnrollmentsByID(userID)
    if err != nil {
        http.Error(w, "Error fetching enrollments", http.StatusInternalServerError)
        log.Printf("Error fetching enrollments for user %d: %v", userID, err)
        return
    }

    for i, enrollment := range enrollments {
        assignments, err := Services.GetAssignmentByCourseID(enrollment.CourseID)
        if err != nil {
            log.Printf("Error fetching assignments for course %d: %v", enrollment.CourseID, err)
            continue 
        }
        enrollments[i].Assignments = assignments
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(enrollments)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding enrollments to JSON: %v", err)
    }
}

func GetWeeklyAssignmentsRequest(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }

    now := time.Now()

    offset := int(now.Weekday())
    weekStart := now.AddDate(0, 0, -offset)
    weekEnd := weekStart.AddDate(0, 0, 7)

    enrollments, err := Services.GetEnrollmentsByID(userID)
    if err != nil {
        http.Error(w, "Error fetching enrollments", http.StatusInternalServerError)
        log.Printf("Error fetching enrollments for user %d: %v", userID, err)
        return
    }

    for i, enrollment := range enrollments {
        assignments, err := Services.GetAssignmentByCourseID(enrollment.CourseID)
        if err != nil {
            log.Printf("Error fetching assignments for course %d: %v", enrollment.CourseID, err)
            continue
        }

        var weeklyAssignments []Models.Assignment
        for _, assignment := range assignments {
            if assignment.DueAt.After(weekStart) && assignment.DueAt.Before(weekEnd) {
                weeklyAssignments = append(weeklyAssignments, assignment)
            }
        }
        enrollments[i].Assignments = weeklyAssignments
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(enrollments)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding enrollments with weekly assignments to JSON: %v", err)
    }
}

func PrioritizeEnrollments(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }
    
    courseID, err := strconv.Atoi(vars["courseID"])
    if err != nil {
        http.Error(w, "Invalid course ID", http.StatusBadRequest)
        log.Printf("Error converting courseID to int: %v", err)
        return
    }

    importance, err := strconv.Atoi(vars["importance"])
    if err != nil || importance < 0 || importance > 9 {
        http.Error(w, "Invalid importance value", http.StatusBadRequest)
        log.Printf("Error converting importance to int or out of range (0-2): %v", err)
        return
    }


    err = Services.SetEnrollmentPriority(userID, courseID, importance)
    if err != nil {
        http.Error(w, "Error updating enrollment priority", http.StatusInternalServerError)
        log.Printf("Error updating enrollment priority for user %d and course %d: %v", userID, courseID, err)
        return
    }

    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Enrollment priority updated successfully"))
}

func HTTPSetBlackOut(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userIDStr := vars["userID"]
    blackoutDays := vars["days"]

 
    userID, err := strconv.Atoi(userIDStr)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }


    err = db.UpdateUserBlackoutDays(userID, blackoutDays)
    if err != nil {
        fmt.Printf("Error updating blackout days for user %d: %v\n", userID, err)
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }


    w.WriteHeader(http.StatusOK)
    fmt.Fprintf(w, "Blackout days updated successfully for user %d", userID)
}




