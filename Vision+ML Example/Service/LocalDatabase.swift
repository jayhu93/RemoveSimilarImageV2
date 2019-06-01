//
//  LocalDatabase.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/28/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import RealmSwift
import ReactiveSwift
import Result

// MARK: LocalDatabaseInputs

protocol LocalDatabaseInputs {
    func addPhotoObjects(_ photoObjects: [PhotoObject])
    func deletePhotoObjects(withIds ids: [String])

    #if !RELEASE
    func deleteAllObjects()
    #endif
}

// MARK: LocalDatabaseOutputs

protocol LocalDatabaseOutputs {
    var getSimilarSetObjectsSignal: Signal<[SimilarSetObject], NoError> { get }
}

// MARK: LocalDatabaseType

protocol LocalDatabaseType {
    var inputs: LocalDatabaseInputs { get }
    var outputs: LocalDatabaseOutputs { get }
}

// MARK: - LocalDatabase

final class LocalDatabase: LocalDatabaseType, LocalDatabaseInputs, LocalDatabaseOutputs {

    var notificationToken: NotificationToken? = nil
    
    private lazy var realm: Realm = {
        func initRealm() -> Realm {
            do {
                let realm = try Realm()
                print("Realm is located at:", realm.configuration.fileURL!)
                return realm
            } catch {
                do {
                    return try Realm()
                } catch {
                    fatalError("Could not instantiate Realm: \(error)")
                }
            }
        }
        return DispatchQueue.mainSyncSafe(execute: initRealm)
    }()

    typealias Dependency = ()

    init(dependency: Dependency) {

        // MARK: Observe SimilarSetObject groups
        let getSimilarSetObjectsIO = Signal<[SimilarSetObject], NoError>.pipe()
        getSimilarSetObjectsSignal = getSimilarSetObjectsIO.output
        
        let similarSetObjects = realm.objects(SimilarSetObject.self)
        self.notificationToken = similarSetObjects.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collectionType):
                getSimilarSetObjectsIO.input.send(value: Array(collectionType))
            case .update(let collectionType, _, _, _):
                getSimilarSetObjectsIO.input.send(value: Array(collectionType))
            case .error:
                fatalError()
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }

    // MARK: LocalDatabaseType

    var inputs: LocalDatabaseInputs { return self }
    var outputs: LocalDatabaseOutputs { return self }

    // MARK: LocalDatabaseInputs

    func addPhotoObjects(_ photoObjects: [PhotoObject]) {
        // I dont need to write Photo object saperately actually, so skip

        try! realm.write {
            for photoObject in photoObjects {
                let startDate = photoObject.timestamp
                let endDate = Calendar.current.nextDate(after: startDate, matching: DateComponents(day: 0), matchingPolicy: .nextTime)!

                let similarSetObjects = realm.objects(SimilarSetObject.self)
                    .filter("timestamp BETWEEN {%@, %@}", startDate, endDate)
                    .sorted(byKeyPath: "timestamp", ascending: false)

                var inserted = false
                for similarSetObject in similarSetObjects {
                    if similarSetObject.ableInsertObject(photoObject) {
                        similarSetObject.photoObjects.append(photoObject)
                        realm.add(similarSetObject, update: true)
                        inserted = true
                        break // End the loop immediately
                    } else {
                        continue // end current loop and start from beginning
                    }
                }
                if !inserted {
                    let new = SimilarSetObject()
                    new.photoObjects.append(photoObject)
                    new.id = photoObject.id
                    self.realm.add(new, update: false)
                }
            }
        }
    }

    func deletePhotoObjects(withIds ids: [String]) {
        let photoObjects = realm.objects(PhotoObject.self).filter("'id' IN $ids")
        realm.delete(photoObjects)
    }

    func deleteAllObjects() {
        realm.deleteAll()
    }

    // MARK: LocalDatabaseOutputs

    let getSimilarSetObjectsSignal: Signal<[SimilarSetObject], NoError>

}

// MARK: - Data Types

extension DispatchQueue {
    class func mainSyncSafe(execute work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    class func mainSyncSafe<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
}
