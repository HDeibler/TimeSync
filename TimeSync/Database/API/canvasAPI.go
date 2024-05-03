package API

import (
	"Database/Models"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

const (
	canvasBaseURL = "https://lvc.instructure.com/api/v1/"
	accessToken   = "5328~pSg9bxO4WG7UmxDbYUIPZ1oyIMIpElwnMJNRfIZzK6MO0u2DAsitfKB7Vvqxk5wC" // Use an environment variable or secure storage for the token
)


func GetCourses() ([]Models.Course, error) {
    url := canvasBaseURL + "courses?include[]=total_scores&enrollment_state=active&per_page=15&state[]=available"
    req, err := http.NewRequest("GET", url, nil)
    if err != nil {
        return nil, err
    }

    req.Header.Add("Authorization", "Bearer "+accessToken)

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
            course.Name = course.Enrollments[0].Name
            courses[i] = course // Update the course in the slice
        }
    }
    

    return courses, nil
}

func GetAssignmentsByCourseID(courseID int) ([]Models.Assignment, error) {
    url := fmt.Sprintf("%scourses/%d/assignments?per_page=60", canvasBaseURL, courseID)

    req, err := http.NewRequest("GET", url, nil)
    if err != nil {
        return nil, err
    }

    req.Header.Add("Authorization", "Bearer "+accessToken)

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

    var assignments []Models.Assignment
    err = json.Unmarshal(body, &assignments)
    if err != nil {
        return nil, err
    }

    return assignments, nil
}

func GetUser(userID int) (Models.User, error) {
	url := fmt.Sprintf("%susers/%d", canvasBaseURL, userID)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return Models.User{}, err
	}

	req.Header.Add("Authorization", "Bearer "+accessToken)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return Models.User{}, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return Models.User{}, err
	}

	var user Models.User
	err = json.Unmarshal(body, &user)
	if err != nil {
		return Models.User{}, err
	}

	return user, nil
}

func GetUserProfile(accessToken string) (Models.User, error) {

    url := canvasBaseURL + "users/self"

    req, err := http.NewRequest("GET", url, nil)
    if err != nil {
        return Models.User{}, err
    }

    req.Header.Add("Authorization", "Bearer " + accessToken)

    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return Models.User{}, err
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return Models.User{}, err
    }

    var user Models.User
    err = json.Unmarshal(body, &user)
    if err != nil {
    return Models.User{}, err
    }

    return user, nil
}
