package db

import (
	"Database/Config"
	"database/sql"
)
var db *sql.DB
func init() {
	db = Config.ConnectDB()
}
