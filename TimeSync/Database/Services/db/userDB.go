package db

import (
	"Database/Models"
	"database/sql"
	"fmt"
)



func InsertUser(user Models.User) error {
	const query = `INSERT INTO users (id, fullname, accesskey) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET fullname = EXCLUDED.fullname;`
	_, err := db.Exec(query, user.ID, user.Name, user.AccessKey)
	if err != nil {
		return fmt.Errorf("InsertUser: %v", err)
	}
	return nil
}

func GetUserByID(userID int) (Models.User, error) {
    const query = `SELECT id, fullname, accesskey, blackout_days FROM users WHERE id = $1;`

    var user Models.User
    row := db.QueryRow(query, userID)
    err := row.Scan(&user.ID, &user.Name, &user.AccessKey, &user.BlackoutDays)
    if err != nil {
        if err == sql.ErrNoRows {
   
            return Models.User{}, fmt.Errorf("no user found with ID %d", userID)
        }
        return Models.User{}, fmt.Errorf("GetUserByID: %v", err)
    }

    return user, nil
}



func GetEnrollmentsByID(userID int) ([]Models.Enrollment, error) {
    const query = `
    SELECT user_id, course_id, computed_current_score, name, prioritize 
    FROM enrollments 
    WHERE user_id = $1;`

    rows, err := db.Query(query, userID)
    if err != nil {
        return nil, fmt.Errorf("GetCoursesByUserID: %v", err)
    }
    defer rows.Close()

    var enrollments []Models.Enrollment
    for rows.Next() {
        var enrollment Models.Enrollment
        err := rows.Scan( &enrollment.UserID, &enrollment.CourseID, &enrollment.ComputedCurrentScore, &enrollment.Name, &enrollment.Prioritize)
        if err != nil {
            return nil, fmt.Errorf("GetCoursesByUserID: %v", err)
        }
        enrollments = append(enrollments, enrollment)
    }

    if err = rows.Err(); err != nil {
        return nil, fmt.Errorf("GetCoursesByUserID: %v", err)
    }

    return enrollments, nil
}



func InsertEnrollment(enrollment Models.Enrollment) error {
	const query = `
	INSERT INTO enrollments (user_id, course_id, computed_current_score, name) 
	VALUES ($1, $2, $3, $4)
	ON CONFLICT (user_id, course_id) DO UPDATE 
	SET computed_current_score = EXCLUDED.computed_current_score;`

	_, err := db.Exec(query, enrollment.UserID, enrollment.CourseID, enrollment.ComputedCurrentScore, enrollment.Name)
	if err != nil {
		return fmt.Errorf("InsertEnrollment: %v", err)
	}
	return nil
}


func UpdateSpecificEnrollmentPriority(userID int, courseID int, priority int) error {
    query := `UPDATE enrollments SET prioritize = $1 WHERE user_id = $2 AND course_id = $3`
    _, err := db.Exec(query, priority, userID, courseID)
    if err != nil {
        return fmt.Errorf("UpdateSpecificEnrollmentPriority error: %v", err)
    }
    return nil
}


func UpdateUserBlackoutDays(userID int, blackoutDays string) error {
    query := `UPDATE users SET blackout_days = $1 WHERE id = $2;`
    _, err := db.Exec(query, blackoutDays, userID)
    if err != nil {
        return fmt.Errorf("UpdateUserBlackoutDays error: %v", err)
    }
    return nil
}


