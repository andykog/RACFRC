import UIKit
import CoreData
import ReactiveCocoa
import enum Result.NoError
import RACMutableCollectionProperty

class RACFRC: NSObject {
    
    class Section: MutableCollectionSection<NSManagedObject> {
        let name: String?
        let indexTitle: String?
        init(objects: [NSManagedObject], sectionName name: String?, indexTitle: String?) {
            self.name = name
            self.indexTitle = indexTitle
            super.init(objects)
        }
    }
    
    private let buffer: MutableCollectionProperty<Section> = MutableCollectionProperty([])
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
    
    func reload() {
        if self.isUpdating {
            fatalError("Attempt to reload RACFRC during update")
        }
        self.property?.value = self.frcValue
    }
    
    var isUpdating = false {
        didSet {
            if self.isUpdating != oldValue {
                if self.isUpdating {
                    if let property = self.property { self.buffer.value = property.value }
                } else {
                    self.property?.value = self.buffer.value
                    self.buffer.value = []
                }
            }
        }
    }
    
    private var frcValue: [Section] {
        return frc?.sections?.map { self.readFRCSection($0) } ?? []
    }
    
    private var suitableProperty: MutableCollectionProperty<Section>? {
        if self.isUpdating {
            return self.buffer
        } else {
            return self.property
        }
    }
    
    private func readFRCSection(frcSection: NSFetchedResultsSectionInfo) -> Section {
        let objects = frcSection.objects!.map { $0 as! NSManagedObject }
        return Section(objects: objects, sectionName: frcSection.name, indexTitle: frcSection.indexTitle)
    }
    
}


extension RACFRC: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.isUpdating = true
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            self.suitableProperty?.insert(anObject as! NSManagedObject, atIndexPath: newIndexPath!)
            
        case .Delete:
            self.suitableProperty?.removeAtIndexPath(indexPath!)
            
        case .Update:
            self.suitableProperty?.replace(element: anObject as! NSManagedObject, atIndexPath: indexPath!)
            
        case .Move:
            self.suitableProperty?.move(fromIndexPath: indexPath!, toIndexPath: newIndexPath!)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            let section = self.readFRCSection(sectionInfo)
            self.suitableProperty?.insert(section, atIndex: sectionIndex)
        case .Delete:
            self.suitableProperty?.removeAtIndex(sectionIndex)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.isUpdating = false
    }
    
}
