package main

import (
	"Database/routes"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
    r := mux.NewRouter()
    routes.RegisterRoutes(r)
  
    
    fmt.Println("Server Start")
    if err := http.ListenAndServe(":5050", r); err != nil {
        log.Fatalf("Error starting server: %v", err)
    }
}
