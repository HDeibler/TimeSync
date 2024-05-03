import SwiftUI
import CoreData

@main
struct TimeShawdyApp: App {

    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var body: some Scene {
        WindowGroup {
            if UserDefaultsManager.isSetupComplete {
                ContentView()
                    .environment(\.managedObjectContext, persistentContainer.viewContext)

                    
            } else {
                SetupView()
                    .environment(\.managedObjectContext, persistentContainer.viewContext)
                    
                    
            }

        }
    }
}



