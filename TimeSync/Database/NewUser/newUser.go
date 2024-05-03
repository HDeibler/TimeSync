package NewUser

import (
	"Database/Models"
	"Database/Services"
	"Database/Services/db"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

const canvasBaseURL = "https://lvc.instructure.com/api/v1/"

func HTTPCreateUserProfile(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    accessKey := vars["accessKey"]
    fmt.Println("Access Key:", accessKey) // Debug log

    user, err := createUserProfile(accessKey)
    if err != nil {
        fmt.Println("Error in CreateUserProfile:", err) // Debug log
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    fmt.Println("User Created:", user) // Debug log

    w.Header().Set("Content-Type", "application/json")
    if err := json.NewEncoder(w).Encode(user); err != nil {
        fmt.Println("Error encoding user to JSON:", err) // Debug log
        http.Error(w, "Error encoding response", http.StatusInternalServerError)
    }
}




func createUserProfile(accessToken string) (Models.User, error) {
    fmt.Println("Access Token:", accessToken) // Debug log

    canvasURL := canvasBaseURL + "users/self"
    req, err := http.NewRequest("GET", canvasURL, nil)
    if err != nil {
        fmt.Println("Error creating request:", err) // Debug log
        return Models.User{}, err
    }

    req.Header.Add("Authorization", "Bearer " + accessToken)


    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        fmt.Println("Error on client.Do:", err) // Debug log
        return Models.User{}, err
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        fmt.Println("Error reading response body:", err) // Debug log
        return Models.User{}, err
    }

    var user Models.User
    err = json.Unmarshal(body, &user)
    if err != nil {
        fmt.Println("Error unmarshaling user:", err) // Debug log
        return Models.User{}, err
    }

    fmt.Println("Retrieved User:", user) // Debug log
	user.AccessKey = accessToken
    err = db.InsertUser(user)
    if err != nil {
        fmt.Println("Error inserting user into database:", err) // Debug log
    }

    courses, err := getCoursesForNewUser(accessToken)
    if err != nil {
        fmt.Println("Error fetching courses:", err) // Debug log
        return Models.User{}, err
    }

    insertCoursesForNewUser(courses)
	
	Services.CanvasGetAssignmentsForUserAndGlobal(user.ID)
    return user, nil
}




func getCoursesForNewUser(accessToken string) ([]Models.Course, error) {
    url := canvasBaseURL + "courses?include[]=total_scores&enrollment_state=active&per_page=15&state[]=available"
    
    req, err := http.NewRequest("GET", url, nil)
    if err != nil {
        return nil, err
    }

    req.Header.Add("Authorization", "Bearer " + accessToken)

    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }

    var courses []Models.Course
    err = json.Unmarshal(body, &courses)
    if err != nil {
        return nil, err
    }

    for i, course := range courses {
        if len(course.Enrollments) > 0 {
            course.Enrollments[0].CourseID = course.CourseID
            courses[i] = course 
        }
    }

    
    return courses, nil
}


func insertCoursesForNewUser(courses []Models.Course) {

    for _, course := range courses {
       
        if course.EnrollmentTermID == 133 {
            
			fmt.Println("Course:", course)
            err := db.InsertCourse(course)
            if err != nil {
                log.Printf("Error inserting course into the database: %v", err)
                continue 
            }

          
            for _, enrollment := range course.Enrollments {
              
                enrollment.Name = course.Name
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




