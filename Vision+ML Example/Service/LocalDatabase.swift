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

// MARK: LocalDatabaseInputs

protocol LocalDatabaseInputs {
    func addPhotoObject(_ photoObject: PhotoObject)
    func updatePhotoObject(withId id: String, photoObject: PhotoObject)
    func deletePhotoObject(withId id: String)

    func returnSomeResults()

    #if !RELEASE
    func deleteAllObjects()
    #endif
}

// MARK: LocalDatabaseOutputs

protocol LocalDatabaseOutputs {
}

// MARK: LocalDatabaseType

protocol LocalDatabaseType {
    var inputs: LocalDatabaseInputs { get }
    var outputs: LocalDatabaseOutputs { get }
}

// MARK: - LocalDatabase

final class LocalDatabase: LocalDatabaseType, LocalDatabaseInputs, LocalDatabaseOutputs {

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
            fatalError("Realm Could not get created.. Nothing to see here")
        }
        return DispatchQueue.mainSyncSafe(execute: initRealm)
    }()

    typealias Dependency = ()

    init(dependency: Dependency) {
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

    // MARK: LocalDatabaseOutputs

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

    func returnSomeResults() {
        let photoObjects = realm.objects(PhotoObject.self)

        var similarPhotoGroups = [[PhotoObject]]()
        let photoArray = Array(photoObjects)

        for (index, photo) in photoArray.enumerated() {
            guard photo.grouped == false else { break }
            var similarGroup = [PhotoObject]()
            similarGroup.append(photo)
            let currentPhotoSimilarArray = Array(photo.similarArray)
            for (innerIndex, innerPhoto) in photoArray.enumerated() {
                if photo.containsElementsFrom(anotherArray: Array(innerPhoto.similarArray)) {
                    similarGroup.append(innerPhoto)
                }
            }
            similarPhotoGroups.append(similarGroup)
        }
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
