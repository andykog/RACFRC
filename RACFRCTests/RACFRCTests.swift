import XCTest
import CoreData
import ReactiveCocoa
@testable import RACFRC

class RACFRCTests: XCTestCase {
    
    var filesViewModel: FilesViewModel!
    let disposables = CompositeDisposable()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func insertFiles(ids: [Int]) -> [File] {
        return ids.enumerate().map { i, id in
            let file = CoreDataHelper.findOrCreateInstance("File", predicate: NSPredicate(format: "id = %d", id)) as! File
            file.id = id
            file.section = "A"
            return file
        }
    }
    
    func testFinished(error: NSError?) {
        if let error = error { print("------- ERROR -------\n\(error)\n---------------------") }
        self.disposables.dispose()
        CoreDataHelper.managedObjectContext.rollback()
    }
    
    func testInsertingRows() {
        self.insertFiles([0])
        var insertedFiles: [File] = []
        let expectation = expectationWithDescription("Change")
        self.filesViewModel = FilesViewModel()
        
        self.disposables += self.filesViewModel.files.changes.startWithNext { change in
            if case .Composite(let changes) = change where changes.first?.element is File {
                let indexPath = changes.map({$0.indexPath!})
                let elements = changes.map({$0.element as! File})
                let operations = changes.map({$0.operation!})
                XCTAssertEqual(indexPath, [[0, 1], [0, 2]])
                XCTAssertEqual(elements, [insertedFiles[0], insertedFiles[1]])
                XCTAssertEqual(operations, [.Insertion, .Insertion])
                expectation.fulfill()
            }
        }
        
        insertedFiles += self.insertFiles([1, 2])
        
        waitForExpectationsWithTimeout(NSTimeInterval(1)) { self.testFinished($0) }
        
    }
    
    func testRemovingRows() {
        self.insertFiles([0])
        var removedFiles: [File] = self.insertFiles([1, 2])
        let expectation = expectationWithDescription("Change")
        self.filesViewModel = FilesViewModel()
        
        self.disposables += self.filesViewModel.files.changes.startWithNext { change in
            if case .Composite(let changes) = change where changes.first?.element is File {
                let indexPath = changes.map({$0.indexPath!})
                let elements = changes.map({$0.element as! File})
                let operations = changes.map({$0.operation!})
                XCTAssertEqual(indexPath, [[0, 2], [0, 1]])
                XCTAssertEqual(elements, [removedFiles[1], removedFiles[0]])
                XCTAssertEqual(operations, [.Removal, .Removal])
                expectation.fulfill()
            }
        }
        
        CoreDataHelper.removeItems("File", predicate: NSPredicate(format: "id != %d", 0))
        
        waitForExpectationsWithTimeout(NSTimeInterval(1)) { self.testFinished($0) }
        
    }
    
    func testMovingRows() {
        let myFiles = self.insertFiles([0, 1, 2, 3])
        let expectation = expectationWithDescription("Change")
        self.filesViewModel = FilesViewModel()
        
        self.disposables += self.filesViewModel.files.changes.startWithNext { change in
            if case .Composite(let changes) = change where changes.first?.element is File {
                let indexPath = changes.map({$0.indexPath!})
                let elements = changes.map({$0.element as! File})
                let operations = changes.map({$0.operation!})
                XCTAssertEqual(indexPath, [[0, 0], [0, 3]])
                XCTAssertEqual(elements, [myFiles[0], myFiles[0]])
                XCTAssertEqual(operations, [.Removal, .Insertion])
                expectation.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            myFiles[0].id = 9
        }
        
        waitForExpectationsWithTimeout(NSTimeInterval(1)) { self.testFinished($0) }
    }
    
    func testUpdatingRows() {
        let myFiles = self.insertFiles([0, 1, 2, 3])
        let expectation = expectationWithDescription("Change")
        self.filesViewModel = FilesViewModel()
        
        self.disposables += self.filesViewModel.files.changes.startWithNext { change in
            if case .Composite(let changes) = change where changes.first?.element is File {
                let indexPath = changes.map({$0.indexPath!})
                let elements = changes.map({$0.element as! File})
                let operations = changes.map({$0.operation!})
                XCTAssertEqual(indexPath, [[0, 0], [0, 0]])
                XCTAssertEqual(elements, [myFiles[0], myFiles[0]])
                XCTAssertEqual(operations, [.Removal, .Insertion])
                expectation.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            myFiles[0].id = -1
        }
        
        waitForExpectationsWithTimeout(NSTimeInterval(1)) { self.testFinished($0) }
    }

}
