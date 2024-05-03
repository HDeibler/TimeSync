//
//  SettingsView.swift
//  TimeShawdy
//
//  Created by Hunter Deibler on 2/6/24.
//

import Foundation
import SwiftUI
import CoreData

struct SettingsView: View {
    @Binding var apiKeyExists: Bool
    @State private var showingEraseDataAlert = false
    
    
    @State private var apiKey: String = ""
    @State private var showingConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: APIKeySettingView(apiKeyExists: $apiKeyExists)) {
                        Text("API Key")
                    }
                    
                    Button("Erase User Data", role: .destructive) {
                        showingEraseDataAlert = true // Show the alert
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Warning", isPresented: $showingEraseDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    eraseUserData() // Call the function to erase data
                }
            } message: {
                Text("All your data will be erased if you continue.")
            }
        }
    }
    private func eraseUserData() {
        UserDefaultsManager.isSetupComplete = false
        
        
        CoreDataManager.shared.clearExistingUserData(entityNames: ["User", "EnrollmentEntity", "Assignments"])
        apiKeyExists = false
        
        
        
    }
    
    
    
    struct APIKeySettingView: View {
        @Binding var apiKeyExists: Bool
        @State private var apiKey: String = ""
        @State private var showingConfirmation: Bool = false
        
        var body: some View {
            Form {
                Section(header: Text("API Key")) {
                    TextField("Enter API Key", text: $apiKey)
                    
                    if !apiKeyExists {
                        Button("Save") {
                            saveApiKey()
                        }
                        .disabled(apiKey.isEmpty)
                    } else if apiKeyExists {
                        Button("Delete API Key", role: .destructive) {
                            deleteApiKey()
                        }
                    }
                }
            }
            .navigationTitle("API Key Settings")
            .onAppear(perform: loadUserAccessKey)
        }
        
        private func loadUserAccessKey() {
            let context = CoreDataManager.shared.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            
            do {
                let results = try context.fetch(fetchRequest)
                if let user = results.first {
                
                    self.apiKey = user.accessKey ?? ""
                    self.apiKeyExists = !self.apiKey.isEmpty
                }
            } catch {
                print("Failed to fetch User: \(error)")
            }
        }
        
        private func saveApiKey() {
            UserDefaults.standard.set(apiKey, forKey: "APIKey")
            
            let context = CoreDataManager.shared.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            
            do {
                let results = try context.fetch(fetchRequest)
                if let user = results.first {
                    user.accessKey = apiKey
                    try context.save()
                }
            } catch {
                print("Failed to save API key to User entity: \(error)")
            }
            
            apiKeyExists = true
            showingConfirmation = true
        }
        
        private func deleteApiKey() {
            UserDefaults.standard.removeObject(forKey: "APIKey")
           
            let context = CoreDataManager.shared.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            
            do {
                let results = try context.fetch(fetchRequest)
                CoreDataManager.shared.clearCalendarEvents()
                if let user = results.first {
                    user.accessKey = nil
                    try context.save()
                }
            } catch {
                print("Failed to delete API key from User entity: \(error)")
            }
            
            apiKey = ""
            apiKeyExists = false
            showingConfirmation = true
        }
    }
}


