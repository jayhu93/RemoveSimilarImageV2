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
    func existInDatabase(_ id: String) -> Bool

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
        DispatchQueue.main.sync {
            struct TempDataStore {
                var similarSetObjects: [SimilarSetObject]

                mutating func sameDaySet(_ photoObject: PhotoObject) -> [SimilarSetObject] {
                    var sameDaySets = [SimilarSetObject]()
                    for similarSet in similarSetObjects {
                        if Calendar.current.isDate(similarSet.timestamp, inSameDayAs: photoObject.timestamp) {
                            sameDaySets.append(similarSet)
                        }
                    }
                    return sameDaySets
                }

                mutating func add(_ similarSet: SimilarSetObject) {
                    if let existing = similarSetObjects.first(where: { $0.id == similarSet.id }) {
                        if let index = similarSetObjects.firstIndex(of: existing) {
                            similarSetObjects.remove(at: index)
                            similarSetObjects.insert(similarSet, at: index)
                        }
                    } else {
                        similarSetObjects.append(similarSet)
                    }

                }
            }
            // first fetch all similarsetobject in memory
            let similarSetObjects = realm.objects(SimilarSetObject.self)
            var tempDataStore = TempDataStore(similarSetObjects: Array(similarSetObjects))

            // have an temp array to hold all of those, and append new one in them
            // after the loops are done, update those objects
            for photoObject in photoObjects {

                let similarSetObjects = tempDataStore.sameDaySet(photoObject)

                var inserted = false
                for similarSetObject in similarSetObjects {
                    if similarSetObject.ableInsertObject(photoObject) {
                        let dupSimilarObject = similarSetObject
                        dupSimilarObject.photoObjects.append(photoObject)
                        tempDataStore.add(dupSimilarObject)
                        inserted = true
                        break // End the loop immediately
                    }
                }
                if !inserted {
                    let new = SimilarSetObject()
                    new.photoObjects.append(photoObject)
                    new.id = photoObject.id
                    new.timestamp = photoObject.timestamp
                    tempDataStore.add(new)
                }
            }

            try! realm.write {
                realm.add(tempDataStore.similarSetObjects, update: true)
            }
        }
    }

    func deletePhotoObjects(withIds ids: [String]) {
        let photoObjects = realm.objects(PhotoObject.self).filter("'id' IN $ids")
        try! realm.write {
            realm.delete(photoObjects)
        }
    }

    func deleteAllObjects() {
        try! realm.write {
            realm.deleteAll()
        }
    }

    func existInDatabase(_ id: String) -> Bool {
        let objects = realm.objects(PhotoObject.self).filter("id == %@", id)
        return objects.count > 0
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
