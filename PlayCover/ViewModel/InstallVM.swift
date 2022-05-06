//
//  InstallSteps.swift
//  PlayCover
//

import Foundation

enum InstallStepsNatvie : String {
    case unzip = "Unzipping app", wrapper = "Creating app wrapper", playtools = "Installing PlayTools", sign = "Signing app", library = "Adding app to library", begin = "Copying app",
    finish = "Finished"
}

class InstallVM : ObservableObject  {
   
    @Published var status : InstallStepsNatvie = .begin
    @Published var progress = 0.0
    @Published var installing  = false
    
    static let shared = InstallVM()
    
    func next(_ step : InstallStepsNatvie){
        DispatchQueue.main.async {
            self.progress = 0
            self.status = step
        }
        
        if step == .begin{
            
            DispatchQueue.main.async {
                self.progress = 0
                self.installing = true
                
                DispatchQueue.global(qos: .userInitiated).async {
                    while self.installing == true {
                        usleep(100000)
                        DispatchQueue.main.async {
                            if self.progress < 100 {
                                self.progress += 0.01
                            } else{
                                self.progress = 0
                            }
                        }
                    }
                }
                
            }
    
        }
        
        if step == .finish{
            DispatchQueue.main.async {
                self.installing = false
            }
        }
    }
    
}
