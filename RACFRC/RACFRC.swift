import UIKit
import CoreData
import ReactiveCocoa
import enum Result.NoError
//import RACMutableCollectionProperty

public class RACFRCSection<T>: MutableCollectionProperty<T> {
    let name: String?
    let indexTitle: String?
    init(objects: [T], sectionName name: String? = nil, indexTitle: String? = nil) {
        self.name = name
        self.indexTitle = indexTitle
        super.init(objects)
    }
}

public class RACFRC<T>: NSObject, NSFetchedResultsControllerDelegate {
    
    public typealias Section = RACFRCSection<T>
    
    private weak var property: MutableCollectionProperty<Section>?
    private weak var frc: NSFetchedResultsController?
    
    init(frc: NSFetchedResultsController?, property: MutableCollectionProperty<Section>) {
        self.frc = frc
        self.property = property
        super.init()
        self.property?.value = self.frcValue
        frc?.delegate = self
    }
    
    deinit {
        self.frc?.delegate = nil
    }
    
    
    // All the changes after controllerWillChangeContent will be stored here
    
    private var insertedRowsIndices: [Int: Set<Int>] = [:]
    private var removedRowsIndices:  [Int: Set<Int>] = [:]
    private var insertedSectionsIndices: Set<Int> = Set()
    private var removedSectionsIndices:  Set<Int> = Set()
    private var insertedRows: [Int: [Int: T]] = [:]
    private var insertedSections: [Int: Section] = [:]
    
    
    public func reload() {
        if self.isUpdating {
            fatalError("Attempt to reload RACFRC during update")
        }
        self.property?.value = self.frcValue
    }
    
    public var isUpdating = false {
        didSet {
            if self.isUpdating != oldValue {
                if self.isUpdating == false {
                    self.property?.isUpdating = true
                    self.insertedSectionsIndices.sort({ $0 < $1 }).forEach { index in
                        self.property?.insert(self.insertedSections[index]!, atIndex: index)
                    }
                    self.insertedSectionsIndices.sort({ $0 > $1 }).forEach { index in
                        self.property?.removeAtIndex(index)
                    }
                    self.insertedRowsIndices.keys.forEach { sectionIndex in
                        self.insertedRowsIndices[sectionIndex]!.sort({ $0 < $1 }).forEach { rowIndex in
                            let row = self.insertedRows[sectionIndex]![rowIndex]!
                            self.property?[sectionIndex].insert(row, atIndex: rowIndex)
                        }
                    }
                    self.removedRowsIndices.keys.forEach { sectionIndex in
                        self.removedRowsIndices[sectionIndex]!.sort({ $0 > $1 }).forEach { rowIndex in
                            self.property?[sectionIndex].removeAtIndex(rowIndex)
                        }
                    }
                    self.property?.isUpdating = false
                    self.insertedRows = [:]
                    self.insertedSections = [:]
                    self.insertedRowsIndices = [:]
                    self.removedRowsIndices = [:]
                    self.insertedSectionsIndices = Set()
                    self.removedSectionsIndices = Set()
                }
            }
        }
    }
    
    private var frcValue: [Section] {
        return frc?.sections?.map { self.readFRCSection($0) } ?? []
    }

    
    private func readFRCSection(frcSection: NSFetchedResultsSectionInfo) -> Section {
        let objects = frcSection.objects!.map { object -> T in
            if let object = object as? T { return object }
            fatalError("Can't cast fetched object of type \(object.dynamicType) to \(T.self)")
        }
        return Section(objects: objects, sectionName: frcSection.name, indexTitle: frcSection.indexTitle)
    }
    
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.isUpdating = true
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            let tObject = anObject as! T
            if self.isUpdating {
                if self.insertedRowsIndices[newIndexPath!.section] == nil {
                    self.insertedRowsIndices[newIndexPath!.section] = Set()
                }
                self.insertedRowsIndices[newIndexPath!.section]!.insert(newIndexPath!.row)
                if self.insertedRows[newIndexPath!.section] == nil {
                    self.insertedRows[newIndexPath!.section] = [:]
                }
                self.insertedRows[newIndexPath!.section]![newIndexPath!.row] = tObject
            } else {
                self.property?[newIndexPath!.section].insert(tObject, atIndex: newIndexPath!.row)
            }
            
        case .Delete:
            if self.isUpdating {
                if self.removedRowsIndices[indexPath!.section] == nil {
                    self.removedRowsIndices[indexPath!.section] = Set()
                }
                self.removedRowsIndices[indexPath!.section]!.insert(indexPath!.row)
            } else {
                self.property?[indexPath!.section].removeAtIndex(indexPath!.row)
            }
            
        case .Update:
            self.property?.replace(element: anObject as! NSManagedObject, atIndexPath: indexPath!)
            
        case .Move:
            self.property?.move(fromIndexPath: indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            let section = self.readFRCSection(sectionInfo)
            if self.isUpdating {
                self.insertedSectionsIndices.insert(sectionIndex)
                self.insertedSections[sectionIndex] = section
            } else {
                self.property?.insert(section, atIndex: sectionIndex)
            }
        case .Delete:
            if self.isUpdating {
                self.removedSectionsIndices.insert(sectionIndex)
            } else {
                self.property?.removeAtIndex(sectionIndex)
            }
        default:
            break
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.isUpdating = false
    }
    
}
