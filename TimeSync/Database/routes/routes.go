package routes

import (
	"Database/NewUser"
	Router "Database/routes/Routers"

	"github.com/gorilla/mux"
)


func RegisterRoutes(r *mux.Router) {
    //User routes
    r.HandleFunc("/user/{userID}", Router.HandleUserRequest).Methods("GET")
    r.HandleFunc("/user/{userID}/enrollments", Router.HandleCoursesRequest).Methods("GET")
    r.HandleFunc("/user/{userID}/enrollments/assignments", Router.GetAssignmentsRequest).Methods("GET")
    r.HandleFunc("/user/{userID}/enrollments/assignments/currentweek", Router.GetWeeklyAssignmentsRequest).Methods("GET")
    r.HandleFunc("/user/{userID}/enrollments/{courseID}/prioritize/{importance}", Router.PrioritizeEnrollments).Methods("POST")



   

    r.HandleFunc("/API/create/user/{accessKey}", NewUser.HTTPCreateUserProfile).Methods("POST")
    /****
    Response 
    {"id":10723,"name":"Hunter Deibler","accessKey":"5328~pSg9bxO4WG7UmxDbYUIPZ1oyIMIpElwnMJNRfIZzK6MO0u2DAsitfKB7Vvqxk5wC","blackoutDays":"","parsedblackoutDays":null}
    ****/
    
    r.HandleFunc("/API/create/schedule/{userID}/{date}", Router.HTTPCreateSchedule).Methods("GET")
        
    //Utlity routes
    r.HandleFunc("/utility/update/coursetime/{courseID}/{day}/{time}", Router.HandleCourseTime).Methods("POST")
    r.HandleFunc("/utility/get/course/{courseID}", Router.HTTPGetCourse).Methods("GET")
    r.HandleFunc("/user/{userID}/set/blackout/{days}", Router.HTTPSetBlackOut).Methods("POST")
    













}

