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
import Photos

// MARK: LocalDatabaseInputs

protocol LocalDatabaseInputs {
    func addPhotoObjects(_ photoObjects: [PhotoObject])
    func deletePhotoObjects(withIds ids: [String])
    func existInDatabase(_ id: String) -> Bool
    func markKeepAll(_ setID: String)
    func removeAll(_ setID: String)
    func removeSelected(_ setID: String, selectedIndices: [Int])
    #if !RELEASE
    func deleteAllObjects()
    #endif
}

// MARK: LocalDatabaseOutputs

protocol LocalDatabaseOutputs {
    var getSimilarSetObjectsSignal: Signal<[SimilarSetObject], NoError> { get }
    func numberOfPhotoObjects() -> Int
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
        
        let similarSetObjects = realm.objects(SimilarSetObject.self).filter("photoObjects.@count > 1 && showSet == true")
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

                init(similarSetObjects: [SimilarSetObject]) {
                    self.similarSetObjects = similarSetObjects.sorted(by: { $0.timestamp > $1.timestamp })
                }

                mutating func sameDayHourSet(_ photoObject: PhotoObject) -> [SimilarSetObject] {
                    var sameDayHourSets = [SimilarSetObject]()
                    for similarSet in similarSetObjects {
                        if Calendar.current.isDate(similarSet.timestamp, inSameDayAs: photoObject.timestamp) {
                            let hour = Calendar.current.component(.hour, from: photoObject.timestamp)
                            let hour1 = Calendar.current.component(.hour, from: similarSet.timestamp)
                            if hour == hour1 {
                                sameDayHourSets.append(similarSet)
                            }
                        }
                    }
                    return sameDayHourSets
                }

                mutating func add(_ similarSet: SimilarSetObject) {
                    if let existing = similarSetObjects.first(where: { $0.id == similarSet.id }) {
                        if let index = similarSetObjects.firstIndex(of: existing) {
                            similarSetObjects.remove(at: index)
                            similarSetObjects.insert(similarSet, at: index)
                        }
                    } else {
                        var copy = similarSetObjects
                        copy.append(similarSet)
                        similarSetObjects = copy.sorted(by: { $0.timestamp > $1.timestamp })
                    }
                }
            }
            // first fetch all similarsetobject in memory
            let similarSetObjects = realm.objects(SimilarSetObject.self)
            var tempDataStore = TempDataStore(similarSetObjects: Array(similarSetObjects))

            // have an temp array to hold all of those, and append new one in them
            // after the loops are done, update those objects
            realm.beginWrite()
            //            try! realm.write {
            for photoObject in photoObjects {

                let similarSetObjects = tempDataStore.sameDayHourSet(photoObject)

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
            realm.add(tempDataStore.similarSetObjects, update: true)
            try! realm.commitWrite()
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

    func numberOfPhotoObjects() -> Int {
        let photoObjects = realm.objects(PhotoObject.self)
        return photoObjects.count
    }

    func markKeepAll(_ setID: String) {
        guard let object = realm.object(ofType: SimilarSetObject.self, forPrimaryKey: setID) else { return }
        try! realm.write {
            object.showSet = false
        }
    }

    func removeAll(_ setID: String) {
        guard  let object = realm.object(ofType: SimilarSetObject.self, forPrimaryKey: setID) else { return }
        let photoIDs = Array(object.photoObjects.map { $0.id })
        try! realm.write {
            realm.delete(object)
        }
//        photoLibraryService.inputs.removePhotos(photoIDs)
        PHPhotoLibrary.shared().performChanges({
            let imageAssetToDelete = PHAsset.fetchAssets(withLocalIdentifiers: photoIDs, options: nil)
            PHAssetChangeRequest.deleteAssets(imageAssetToDelete)
        }, completionHandler: {success, error in
            print(success ? "Success" : error as Any )
        })
    }

    func removeSelected(_ setID: String, selectedIndices: [Int]) {
        let sortedIndices = selectedIndices.sorted(by: >)
        guard let object = realm.object(ofType: SimilarSetObject.self, forPrimaryKey: setID) else { return }
        let elements =  sortedIndices.map { object.photoObjects[$0] }
        try! realm.write {
            sortedIndices.forEach { object.photoObjects.remove(at: $0) }
        }
//        photoLibraryService.inputs.removePhotos(elements.map { $0.id })
        let photoIDs = elements.map { $0.id }
        PHPhotoLibrary.shared().performChanges({
            let imageAssetToDelete = PHAsset.fetchAssets(withLocalIdentifiers: photoIDs, options: nil)
            PHAssetChangeRequest.deleteAssets(imageAssetToDelete)
        }, completionHandler: {success, error in
            print(success ? "Success" : error as Any )
        })
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
