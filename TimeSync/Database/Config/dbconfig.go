package Config

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

const (
    host     = "timedb.cnygsg46imst.us-east-2.rds.amazonaws.com"
    port     = 5432 // Default port
    user     = "postgres"
    password = "Flyersrock101"
    dbname   = "postgres"
)

func ConnectDB() *sql.DB {
    psqlInfo := fmt.Sprintf("host=%s port=%d user=%s "+
        "password=%s dbname=%s sslmode=require",
        host, port, user, password, dbname)

    db, err := sql.Open("postgres", psqlInfo)
    if err != nil {
        log.Fatal("Error connecting to the database: ", err)
    }

    err = db.Ping()
    if err != nil {
        log.Fatal("Database is not reachable: ", err)
    }

    fmt.Println("Successfully connected to the database")
    return db
}
