//
//  Utility.swift
//  DbDemoExampleSwift
//
//  Created by MHB on 7/26/16.
//  Copyright © 2016 MHB. All rights reserved.
//

import UIKit


class DatabaseUtility: NSObject {
    
    class func getPath(_ fileName: String) -> String {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return fileURL.path
    }
    
    class func copyFile(_ fileName: NSString) {
        let dbPath: String = getPath(fileName as String)
        let fileManager = FileManager.default
        
        //        if userSettings.isDatabaseUpdated() == false {
        let documentsURL = Bundle.main.resourceURL
        let fromPath = documentsURL!.appendingPathComponent(fileName as String)
        var error : NSError?
        do {
            if fileManager.fileExists(atPath: dbPath) {
//                try fileManager.removeItem(atPath: dbPath)
//                print("#DB Remove")
            }
            try fileManager.copyItem(atPath: fromPath.path, toPath: dbPath)
            //                userSettings.setDatabaseUpdated()
            print("#DB Copy")
        } catch let error1 as NSError {
            error = error1
        }
        if (error != nil) {
            print("Error Occured while copying database : \(error!)")
        } else {
            print("database copy successfully")
        }
        //        }
    }
}
