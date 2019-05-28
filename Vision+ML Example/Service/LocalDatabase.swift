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
    func addPhotoObject(_ photoObject: PhotoObject)
    func addPhotoObjects(_ photoObjects: [PhotoObject])
    func updatePhotoObject(withId id: String, photoObject: PhotoObject)
    func deletePhotoObject(withId id: String)
    func deletePhotoObject(withIds ids: [String])
    func getSimilarObjectGroups()

    #if !RELEASE
    func deleteAllObjects()
    #endif
}

// MARK: LocalDatabaseOutputs

protocol LocalDatabaseOutputs {
    var similarPhotoGroupsSignal: Signal<[[PhotoObject]], NoError> { get }
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

        similarPhotoGroupsSignal = getSimilarObjectGroupsIO.output

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

    func addPhotoObject(_ photoObject: PhotoObject) {
        if let _ = realm.object(ofType: PhotoObject.self, forPrimaryKey: photoObject.id) {
            // object already exist, need to update object
            write {
                self.realm.add(photoObject, update: true)
            }
        } else {
            // object doesn't exist
            write {
                self.add(photoObject)
            }
        }
        
        // after the photo object is stored in the databse
        // fetch all the similar set, and check if the photoObject
        // should be group within the same set
        
        let similarSetObjects = Array(realm.objects(SimilarSetObject.self).reversed())
        var inserted = false
        for similarSet in similarSetObjects {
            let newSimilarSet = similarSet
            if newSimilarSet.insertObject(photoObject) {
                write {
                    newSimilarSet.photoObjects.append(photoObject)
                    self.realm.add(newSimilarSet, update: true)
                }
                inserted = true
                break // End the loop immediately
            } else {
               continue // end current loop and start from beginning again
            }
        }
        if !inserted {
            // cretae a new simiarSet
            let new = SimilarSetObject()
            new.photoObjects.append(photoObject)
            new.id = photoObject.id // set id is the id of the first photo object
            write {
                self.realm.add(new, update: true)
            }
        }
    }

    func addPhotoObjects(_ photoObjects: [PhotoObject]) {
        DispatchQueue.main.async {
            for photoObject in photoObjects {
                self.addPhotoObject(photoObject)
            }
        }
    }

    func updatePhotoObject(withId id: String, photoObject: PhotoObject) {
        guard let photoObject = realm.object(ofType: PhotoObject.self, forPrimaryKey: id) else {
            return
        }
        write {
            self.add(photoObject)
        }
    }

    func deletePhotoObject(withId id: String) {
        guard let photoObject = realm.object(ofType: PhotoObject.self, forPrimaryKey: id) else {
            return
        }
        write {
            self.realm.delete(photoObject)
        }
    }

    func deletePhotoObject(withIds ids: [String]) {
        let photoObjects = realm.objects(PhotoObject.self).filter("'id' IN $ids")
        write {
            self.realm.delete(photoObjects)
        }
    }

    // MARK: LocalDatabaseOutputs
    
    let similarPhotoGroupsSignal: Signal<[[PhotoObject]], NoError>
    let getSimilarSetObjectsSignal: Signal<[SimilarSetObject], NoError>

    // MARK: Methods should be declared as private but public for test

    func write(block: @escaping () -> Void) {
        DispatchQueue.mainSyncSafe { [weak self] in
            guard let weakSelf = self else { return }
            guard !weakSelf.realm.isInWriteTransaction else {
                block()
                return
            }

            do {
                try weakSelf.realm.write {
                    block()
                }
            } catch {
                assertionFailure("Failed to write: \(error)")
            }
        }
    }

    func add(_ object: Object) {
        write {
            self.realm.add(object)
        }
    }

    func delete(_ objects: [Object]) {
        write {
            self.realm.delete(objects)
        }
    }

    func deleteAllObjects() {
        write {
            self.realm.deleteAll()
        }
    }

    func objects<O: Object>(objectType: O.Type) -> [O] {
        func returnObjects() -> [O] {
            return Array(realm.objects(O.self))
        }
        return DispatchQueue.mainSyncSafe(execute: returnObjects)
    }

    func object<O: Object>(objectType: O.Type, byID id: Int32) -> O? {
        func returnObject() -> O? {
            return realm.object(ofType: O.self, forPrimaryKey: id)
        }
        return DispatchQueue.mainSyncSafe(execute: returnObject)
    }

    private let getSimilarObjectGroupsIO = Signal<[[PhotoObject]], NoError>.pipe()
    func getSimilarObjectGroups() {
        let photoObjects = realm.objects(PhotoObject.self)

        var similarPhotoGroups = [[PhotoObject]]()
        let photoArray = Array(photoObjects)

        for photo in photoArray {
            guard photo.grouped == false else { continue }
            var similarGroup = [PhotoObject]()
            photo.grouped = true
            similarGroup.append(photo)
            for innerPhoto in photoArray {
                guard photo.id != innerPhoto.id else { continue }
                guard innerPhoto.grouped == false else { continue }
                if photo.containsElementsFrom(anotherArray: Array(innerPhoto.similarArray)) {
                    if let index = photoArray.index(of: innerPhoto) {
                        photoArray[index].grouped = true
                        similarGroup.append(innerPhoto)
                    }
                }
            }
            if similarGroup.count > 1 {
                similarPhotoGroups.append(similarGroup)
            }
        }
        getSimilarObjectGroupsIO.input.send(value: similarPhotoGroups)
    }

    // MARK: Private

    private func deleteAllObjects<O: Object>(of type: O.Type) {
        write { self.realm.delete(self.realm.objects(type)) }
    }
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
