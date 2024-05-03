package db

import (
	"Database/Models"
	"database/sql"
	"fmt"
	"time"
)



func InsertCourse(course Models.Course) error {
    const query = `
    INSERT INTO courses (id, name, enrollment_term_id) 
    VALUES ($1, $2, $3)
    ON CONFLICT (id) DO UPDATE 
    SET name = EXCLUDED.name, 
        enrollment_term_id = EXCLUDED.enrollment_term_id;`

    _, err := db.Exec(query, course.CourseID, course.Name, course.EnrollmentTermID)
    if err != nil {
        return fmt.Errorf("InsertCourse: %v", err)
    }
    return nil
}

func InsertAssignment(assignment Models.Assignment) error {
    const query = `
    INSERT INTO assignments (id, course_id, name, description, due_at, points_possible) 
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (id) DO UPDATE 
    SET course_id = EXCLUDED.course_id, 
        name = EXCLUDED.name, 
        description = EXCLUDED.description,
        due_at = EXCLUDED.due_at,
        points_possible = EXCLUDED.points_possible;`

    _, err := db.Exec(query, assignment.AssignmentID, assignment.CourseID, assignment.Name, assignment.Description, assignment.DueAt, assignment.PointsPossible)
    if err != nil {
        return fmt.Errorf("InsertAssignment: %v", err)
    }
    return nil
}


func GetAssignmentsByCourseID(courseID int) ([]Models.Assignment, error) {
    const query = `
    SELECT id, course_id, name, description, due_at, points_possible 
    FROM assignments 
    WHERE course_id = $1;`

    rows, err := db.Query(query, courseID)
    if err != nil {
        return nil, fmt.Errorf("GetAssignmentsByCourseID query error: %v", err)
    }
    defer rows.Close()

    var assignments []Models.Assignment
    for rows.Next() {
        var a Models.Assignment
        err := rows.Scan(&a.AssignmentID, &a.CourseID, &a.Name, &a.Description, &a.DueAt, &a.PointsPossible)
        if err != nil {
            return nil, fmt.Errorf("GetAssignmentsByCourseID scan error: %v", err)
        }
        assignments = append(assignments, a)
    }

    if err = rows.Err(); err != nil {
        return nil, fmt.Errorf("GetAssignmentsByCourseID rows iteration error: %v", err)
    }

    return assignments, nil
}



func UpdateCourseTime(courseID int, day string, startTimeStr, endTimeStr string) error {
    query := `UPDATE courses SET class_days = $2, class_time_start = $3, class_time_end = $4 WHERE id = $1`
    _, err := db.Exec(query, courseID, day, startTimeStr, endTimeStr)
    if err != nil {
        return fmt.Errorf("UpdateCourseTimeDB error: %v", err)
    }
    return nil
}

func GetCoursesByID(courseID int) (Models.Course, error)  {
	const query = `
	SELECT id, name, enrollment_term_id, class_days, class_time_start, class_time_end 
	FROM courses 
	WHERE id = $1;`

	var course Models.Course
	var classDays sql.NullString
	var classTimeStart, classTimeEnd sql.NullTime // Use sql.NullTime for nullable time fields

	row := db.QueryRow(query, courseID)
	err := row.Scan(&course.CourseID, &course.Name, &course.EnrollmentTermID, &classDays, &classTimeStart, &classTimeEnd)
	if err != nil {
		return Models.Course{}, fmt.Errorf("GetCourseByID: %v", err)
	}

	if classDays.Valid {
		course.ClassDays = classDays.String
	} else {
		course.ClassDays = "" 
	}


	if classTimeStart.Valid {
		course.ClassTimeStart = classTimeStart.Time
	} else {

		course.ClassTimeStart = time.Time{}
	}


	if classTimeEnd.Valid {
		course.ClassTimeEnd = classTimeEnd.Time
	} else {

		course.ClassTimeEnd = time.Time{}
	}

	return course, nil
}

