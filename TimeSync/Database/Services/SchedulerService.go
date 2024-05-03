package Services

import (
	"Database/Models"
	"Database/Services/db"
	"fmt"
	"sort"
	"strings"
	"time"
)

func CreateUserSchedulePrompt(userID int, currentDate string) (Models.FullPromptCompletionModel, error) {
	var fullPromptCompletion Models.FullPromptCompletionModel

	loc, err := time.LoadLocation("America/New_York")
	if err != nil {
		return fullPromptCompletion, fmt.Errorf("error loading timezone: %v", err)
	}

	currentDay, err := time.ParseInLocation("2006-01-02", currentDate, loc)
	if err != nil {
		return fullPromptCompletion, fmt.Errorf("error parsing current date: %v", err)
	}

	user, err := db.GetUserByID(userID)
	if err != nil {
		return fullPromptCompletion, fmt.Errorf("error fetching user: %v", err)
	}

	fullPromptCompletion.Prompt.CurrentDay = currentDay
	fullPromptCompletion.Prompt.StudyBlackoutDays = parseDays(user.BlackoutDays, currentDay, loc, true)

	enrollments, err := db.GetEnrollmentsByID(userID)
	if err != nil {
		return fullPromptCompletion, fmt.Errorf("error fetching enrollments: %v", err)
	}

	weekStart, weekEnd := getWeekRange(currentDay)
	processEnrollments(&fullPromptCompletion, enrollments, weekStart, weekEnd, loc)
    processSchedule(&fullPromptCompletion, enrollments, weekStart, weekEnd, loc)
	return fullPromptCompletion, nil
}

func parseDays(daysStr string, referenceDay time.Time, loc *time.Location, isBlackout bool) []string {
	abbreviations := map[string]time.Weekday{
		"M": time.Monday, "T": time.Tuesday, "W": time.Wednesday,
		"Th": time.Thursday, "F": time.Friday,
		"S": time.Saturday, "SUN": time.Sunday,
	}

	days := strings.Split(daysStr, ",")
	var parsedDays []string
	for _, day := range days {
		if weekday, ok := abbreviations[day]; ok {
			nextDay := getNextWeekday(referenceDay, weekday, loc)
			if isBlackout || nextDay.Before(referenceDay.AddDate(0, 0, 7)) {
				parsedDays = append(parsedDays, nextDay.Format("2006-01-02"))
			}
		}
	}
	return parsedDays
}

func processEnrollments(fullPromptCompletion *Models.FullPromptCompletionModel, enrollments []Models.Enrollment, weekStart, weekEnd time.Time, loc *time.Location) {
    simplifiedEnrollments := []Models.SimplifiedEnrollment{}

    for _, enrollment := range enrollments {
        assignments, err := db.GetAssignmentsByCourseID(enrollment.CourseID)
        if err != nil {
            continue // Ideally, log this error
        }

        simplifiedAssignments := []Models.SimplifiedAssignment{}
        for _, assignment := range assignments {
            if assignment.DueAt.After(weekStart) && assignment.DueAt.Before(weekEnd) {
                dueAtLocal := assignment.DueAt.In(loc).Format("2006-01-02 3:04PM") // Simplified date format
                
                simplifiedAssignments = append(simplifiedAssignments, Models.SimplifiedAssignment{
                    DueAt:          dueAtLocal,
                    PointsPossible: assignment.PointsPossible,
                    Name:           assignment.Name,
                })
            }
        }

        prioritization := getPrioritization(enrollment.Prioritize) // Convert prioritization to a readable format
        simplifiedEnrollments = append(simplifiedEnrollments, Models.SimplifiedEnrollment{
            CourseName:    enrollment.Name,
            Prioritization: prioritization,
            Assignments:   simplifiedAssignments,
        })
    }

   
    fullPromptCompletion.Prompt.SimplifiedEnrollments = simplifiedEnrollments
}

func processSchedule(fullPromptCompletion *Models.FullPromptCompletionModel, enrollments []Models.Enrollment, weekStart, weekEnd time.Time, loc *time.Location) {
  
    courseScheduleMap := make(map[string]*Models.ScheduleEvent)

    for _, enrollment := range enrollments {
        course, err := db.GetCoursesByID(enrollment.CourseID)
        if err != nil {
            continue // Ideally, log this error
        }

        scheduleKey := fmt.Sprintf("%s-%s-%s", course.Name, course.ClassTimeStart.Format("15:04"), course.ClassTimeEnd.Format("15:04"))

        if scheduleEvent, exists := courseScheduleMap[scheduleKey]; exists {
            classDays := parseDays(course.ClassDays, weekStart, loc, false)
   
            scheduleEvent.Day = append(scheduleEvent.Day, classDays...)
        } else {

            courseScheduleMap[scheduleKey] = &Models.ScheduleEvent{
                Day:   parseDays(course.ClassDays, weekStart, loc, false),
                Time:  fmt.Sprintf("%s - %s", course.ClassTimeStart.Format("15:04"), course.ClassTimeEnd.Format("15:04")),
                Event: course.Name,
            }
        }
    }

    for _, event := range courseScheduleMap {

        sort.Strings(event.Day)
        fullPromptCompletion.Prompt.CurrentSchedule = append(fullPromptCompletion.Prompt.CurrentSchedule, *event)
    }


}




func getWeekRange(date time.Time) (time.Time, time.Time) {
	weekday := date.Weekday()
	weekStart := date.AddDate(0, 0, -int(weekday))
	weekEnd := weekStart.AddDate(0, 0, 7)
	return weekStart, weekEnd
}

func getNextWeekday(start time.Time, weekday time.Weekday, loc *time.Location) time.Time {
	daysUntil := int(weekday) - int(start.Weekday())
	if daysUntil < 0 {
		daysUntil += 7
	}
	return start.AddDate(0, 0, daysUntil).In(loc)
}

func getPrioritization(priority int) string {
	switch priority {
	case 0:
		return "Class Priority low"
	case 2:
		return "Class Priority medium"
	case 3:
		return "Class Priority high"
	default:
		return "Class Priority low"
	}
}