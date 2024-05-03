package Services

import (
	"Database/API"
	"Database/Models"
	"encoding/json"
	"fmt"
)


func SendPromptToChatGPT(fullPromptCompletion Models.FullPromptCompletionModel) (Models.FullPromptCompletionModel, error) {
	
	promptJSON, err := json.Marshal(fullPromptCompletion.Prompt)
	if err != nil {
		return fullPromptCompletion, fmt.Errorf("error serializing prompt: %v", err)
	}

	
	client := API.NewClient()
	run, err := API.CreateThreadWithMessage(client, string(promptJSON))
	if err != nil {
		return fullPromptCompletion, fmt.Errorf("error creating thread with message: %v", err)
	}

	
    message, err := API.MonitorRunAndRetrieveMessages(client, run.ThreadID, run.ID)
    if err != nil {
        return fullPromptCompletion, fmt.Errorf("error monitoring run and retrieving messages: %v", err)
    }
	fmt.Println(message)
    
    var completion Models.Completion
    if err := json.Unmarshal([]byte(message), &completion); err != nil {
        return fullPromptCompletion, fmt.Errorf("error deserializing completion: %v", err)
    }

    
    fullPromptCompletion.Completion = completion
    
    return fullPromptCompletion, nil
}
