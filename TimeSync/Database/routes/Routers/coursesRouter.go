package Router

import (
	"Database/Services"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)



func HandleAssignmentsRequest(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }

    assignments, err := Services.CanvasGetAssignmentsForUserAndGlobal(userID)
    if err != nil {
        http.Error(w, "Error fetching assignments", http.StatusInternalServerError)
        log.Printf("Error fetching assignments for user %d: %v", userID, err)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(assignments)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding assignments to JSON: %v", err)
    }
}

func HTTPGetCourse(w http.ResponseWriter, r *http.Request){
    vars :=  mux.Vars(r)
    courseID, err := strconv.Atoi(vars["courseID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting Course ID: %v", err)
        return
    }
    course, err := Services.GetCourseByID(courseID)
    if err != nil {
        http.Error(w, "Error fetching courses", http.StatusInternalServerError)
        log.Printf("Error fetching courses%v: %v", course, err)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(course)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding assignments to JSON: %v", err)
    }


}



func HandleCourseTime(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    
    courseID, err := strconv.Atoi(vars["courseID"])
    if err != nil {
        http.Error(w, "Invalid course ID", http.StatusBadRequest)
        log.Printf("Error converting courseID to int: %v", err)
        return
    }

    day := vars["day"]
    time := vars["time"]

   
    if err := Services.UpdateCourseTime(courseID, day, time); err != nil {
        http.Error(w, "Error updating course time", http.StatusInternalServerError)
        log.Printf("Error updating course time for course %d: %v", courseID, err)
        return
    }

    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Course time updated successfully"))
}

func HandleGetCourseTime(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    courseID, err := strconv.Atoi(vars["courseID"])
    if err != nil {
        http.Error(w, "Invalid course ID", http.StatusBadRequest)
        log.Printf("Error converting courseID to int: %v", err)
        return
    }

    
    course, err := Services.GetCourseByID(courseID)
    if err != nil {
        http.Error(w, "Error fetching course details", http.StatusInternalServerError)
        log.Printf("Error fetching course details for course %d: %v", courseID, err)
        return
    }

  
    response := map[string]interface{}{
        "courseID": course.CourseID,
        "name":     course.Name,
        "day":      course.ClassDays,
        "timeStart": nil, // Assume null by default
        "timeEnd":   nil, // Assume null by default
    }


    if !course.ClassTimeStart.IsZero() {
        response["timeStart"] = course.ClassTimeStart.Format("15:04")
    }
    if !course.ClassTimeEnd.IsZero() {
        response["timeEnd"] = course.ClassTimeEnd.Format("15:04")
    }

    w.Header().Set("Content-Type", "application/json")
    err = json.NewEncoder(w).Encode(response)
    if err != nil {
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
        log.Printf("Error encoding course time details to JSON: %v", err)
    }
}

