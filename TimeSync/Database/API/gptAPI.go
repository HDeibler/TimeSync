package API

import (
	"context"
	"fmt"
	"time"

	openai "github.com/sashabaranov/go-openai"
)

func NewClient() *openai.Client {
	apiKey := ""
	client := openai.NewClient(apiKey)
	return client
}


func CreateThreadWithMessage(client *openai.Client, messageContent string) (*openai.Run, error) {
	ctx := context.Background()
	request := openai.CreateThreadAndRunRequest{
		RunRequest: openai.RunRequest{
			AssistantID:  "asst_1J35In6CwB2Q17KOW37khSTP",
		},
		Thread: openai.ThreadRequest{
			Messages: []openai.ThreadMessage{
				{
					Role:    "user",
					Content: messageContent,
				},
			},
		},
	}

	response, err := client.CreateThreadAndRun(ctx, request)
	if err != nil {
		return nil, err
	}
	return &response, nil
}




func MonitorRunAndRetrieveMessages(client *openai.Client, threadID string, runID string) (string, error) {
	 

	ctx := context.Background()


	for {
		run, err := client.RetrieveRun(ctx, threadID, runID)
		if err != nil {
			return err.Error(), fmt.Errorf("error retrieving run: %w", err)
		}

		if run.Status == openai.RunStatusCompleted {
			fmt.Println("Run completed.")
			break
		}
		time.Sleep(2 * time.Second)
	}


	messagesList, err := client.ListMessage(ctx, threadID, nil, nil, nil, nil)
	if err != nil {
		return err.Error(), fmt.Errorf("error listing messages: %w", err)
	}

	for _, message := range messagesList.Messages {
        if message.Role == "assistant" && len(message.Content) > 0 && message.Content[0].Text != nil {
            return message.Content[0].Text.Value, nil // Return the first assistant message
        }
    }

    return "", fmt.Errorf("no assistant messages found")

}

//fuck you openai and your love for python only
