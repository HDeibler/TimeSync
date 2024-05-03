//
//  SetupManager.swift
//  TimeShawdy
//
//  Created by Hunter Deibler on 2/6/24.
//

import Foundation

struct SetupStep: Identifiable, Equatable {
    static func == (lhs: SetupStep, rhs: SetupStep) -> Bool {
        lhs.id == rhs.id && lhs.isCompleted == rhs.isCompleted && lhs.title == rhs.title && lhs.instruction == rhs.instruction
    }
    
    var id: UUID = UUID()
    var isCompleted: Bool = false
    var title: String
    var instruction: String
    var action: (() -> Void)?
}

class SetupStepsManager: ObservableObject {
    @Published var steps: [SetupStep]
    
    init(steps: [SetupStep]) {
        self.steps = steps
    }
    
    var currentStep: SetupStep? {
        steps.first { !$0.isCompleted }
    }
    
    func completeCurrentStep() {
        if let currentStepIndex = steps.firstIndex(where: { !$0.isCompleted }) {
            let step = steps[currentStepIndex]
            step.action?()
            steps[currentStepIndex].isCompleted = true
        }
    }
}
