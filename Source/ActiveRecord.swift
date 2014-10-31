// ActiveRecord.swift
//
// Copyright (c) 2014 Shintaro Kaneko (http://kaneshinth.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreData

// MARK: - Setup

public class ActiveRecord: NSObject {
    
    /// private sharedInstance
    private class var sharedInstance : ActiveRecord {
        struct Static {
            static let instance : ActiveRecord = ActiveRecord()
        }
        return Static.instance
    }
    
    /// instance variable for static variable driver
    private var sharedDriver: Driver?

    private class var driver: Driver? {
        return ActiveRecord.sharedInstance.sharedDriver
    }
    
    override init() {
        if let coreDataStack = ActiveRecordConfig.sharedInstance.coreDataStack {
            self.sharedDriver = Driver(coreDataStack: coreDataStack)
        }
    }
    
    /**
    Peform block in background queue and save : Manually call timing of save.
    
    :param: block
    :param: saveSuccess
    :param: saveFailure
    */
    public class func saveWithBackgroundBlock(block: (() -> Void)?, saveSuccess: (() -> Void)?, saveFailure: ((error: NSError?) -> Void)?) {
        if let driver = self.driver {
            driver.saveWithBlock(block: block, saveSuccess: saveSuccess, saveFailure: saveFailure)
        }
    }
    
    
    /**
    Perform block in background queue and save and wait till done.
    
    :param: block
    :param: error
    :returns: true if successfully saved.
    */
    public class func saveWithBackgroundBlockAndWait(block: (Void -> Void)?, error: NSErrorPointer) -> Bool {
        if let driver = self.driver {
            return driver.saveWithBlockAndWait(block: block, error: error)
        }
        return false
    }
    
    /**
    Perform in background queue and save (Manually call timing of save.)
    
    :param: block
    :param: saveSuccess
    :param: saveFailure
    */
    public class func saveWithBackgroundBlockWaitSave(block: ((doSave: (() -> Void)) -> Void)?, saveSuccess: (() -> Void)?, saveFailure: ((error: NSError?) -> Void)?) {
        if let driver = self.driver {
            driver.saveWithBlockWaitSave(block: block, saveSuccess: saveSuccess, saveFailure: saveFailure)
        }
    }
    
    /**
    Perform in background queue.
    
    :param: block
    :param: completion
    */
    public class func performBackgroundBlock(block: (() -> Void)?, completion: (() -> Void)?) {
        if let driver = self.driver {
            return driver.performBlock(block: block, completion: completion)
        }
    }
    
    /**
    Perform in background queue and wait til done.
    
    :param: block
    :param: completion
    */
    public class func performBackgroundBlockAndWait(block: (() -> Void)?) {
        if let driver = self.driver {
            return driver.performBlock(block: block, completion: nil, waitUntilFinished: true)
        }
    }

}


public extension NSManagedObject {
    
    public class func create(#entityName: String) -> NSManagedObject? {
        return ActiveRecord.driver?.create(entityName, context: ActiveRecord.driver?.context())
    }
    
    public func save() {
        var error: NSError? = nil
        ActiveRecord.driver?.save(self.managedObjectContext, error: &error)
    }
    
    public func delete() {
        ActiveRecord.driver?.delete(object: self)
    }
    
    public class func find(#entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, offset: Int = 0, limit: Int = 0) -> [AnyObject]? {
        var error: NSError? = nil
        return ActiveRecord.driver?.read(entityName, predicate: predicate, offset: offset, limit: limit, context: ActiveRecord.driver?.context(), error: &error)
    }
    
    public class func findFirst(#entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> AnyObject? {
        var error: NSError? = nil
        if let objects = ActiveRecord.driver?.read(entityName, predicate: predicate, sortDescriptors: sortDescriptors, offset: 0, limit: 1, context: ActiveRecord.driver?.context(), error: &error) {
            return objects.first
        }
        return nil
    }
    
    public class func find(#entityName: String, fetchRequest: NSFetchRequest) -> [AnyObject]? {
        var error: NSError? = nil
        return ActiveRecord.driver?.read(fetchRequest, context: ActiveRecord.driver?.context(), error: &error)
    }
    
    public class func count(#entityName: String, predicate: NSPredicate? = nil) -> Int {
        if let driver = ActiveRecord.driver {
            var error: NSError? = nil
            return driver.count(entityName, predicate: predicate, context: ActiveRecord.driver?.context(), error: &error)
        } else {
            return 0;
        }
    }
}

public extension NSManagedObjectContext {
    public func save() {
        var error: NSError? = nil
        ActiveRecord.driver?.save(self, error: &error)
    }
    
    public class func save() {
        var error: NSError? = nil
        ActiveRecord.driver?.save(ActiveRecord.driver?.context(), error: &error)
    }

    public class func save(error: NSErrorPointer) -> Bool {
        if let driver =  ActiveRecord.driver {
            return driver.save(ActiveRecord.driver?.context(), error: error)
        }
        return false
    }

    public class func context() -> NSManagedObjectContext? {
        return ActiveRecord.driver?.context()
    }
}



