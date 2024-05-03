package Router

import (
	"Database/Services"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)


func HTTPCreateSchedule (w http.ResponseWriter, r *http.Request){
	vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["userID"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        log.Printf("Error converting userID to int: %v", err)
        return
    }
	dateString := vars["date"]

	fmt.Println(dateString)
    const layout = "2006-01-02"
    date, err := time.Parse(layout, dateString)
    if err != nil {
        http.Error(w, "Invalid date format. Please use YYYY-MM-DD format.", http.StatusBadRequest)
        log.Printf("Error parsing date: %v", err)
		log.Printf("Error %v is in wrong format", date)
        return
    }


	
	// Generate the schedule prompt
	schedule, err := Services.CreateUserSchedulePrompt(userID, dateString)
	if err != nil {
		http.Error(w, "Error generating schedule prompt", http.StatusInternalServerError)
		log.Printf("Error generating schedule prompt: %v", err)
		return
	}
	fmt.Println(schedule.Prompt.CurrentDay)

	// Send the prompt to the ChatGPT API
	schedule, err = Services.SendPromptToChatGPT(schedule)
	if err != nil {
		http.Error(w, "Error with ChatGPT API", http.StatusInternalServerError)
		log.Printf("Error with ChatGPT API: %v", err)
		return
	}

	// Return the generated schedule
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(schedule.Completion); err != nil {
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
		log.Printf("Error encoding response: %v", err)
	}
}







	






