import Foundation

class Migrate: ObservableObject {
    static func migrateData() {
        if fm.fileExists(atPath: "/Applications/PlayCover.app") && fm.fileExists(atPath: "/Users/\(NSUserName())/Library/Containers/me.playcover.PlayCover") {
            
            do {
                let items = try fm.contentsOfDirectory(atPath: "/Users/\(NSUserName())/Library/Containers/me.playcover.PlayCover/")

                for item in items {
                    try? fm.moveItem(at: URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/me.playcover.PlayCover/\(item)"), to: URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover/\(item)"))
                }
            } catch {
                fatalError("Failed to migrate data: Insufficient permissions perhaps?")
            }
        }
        
        fm.createFile(atPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover/migrate", contents: nil)
    }
}
