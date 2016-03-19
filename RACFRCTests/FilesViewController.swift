import UIKit
import ReactiveCocoa
import enum Result.NoError
import CoreData
@testable import RACFRC

class FilesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let disposables = CompositeDisposable()
    
    deinit {
        self.disposables.dispose()
    }
    
    let viewModel = FilesViewModel()
    
    func handleChange(change: MutableCollectionChange) {
        switch change {
        case .Remove(let (indexPath, _)):
            if indexPath.count < 2 {
                self.tableView?.deleteSections(NSIndexSet(index: indexPath[0]), withRowAnimation: .Fade)
            } else {
                let indexPath = NSIndexPath(forRow: indexPath[0], inSection: indexPath[1])
                self.tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .Insert(let (indexPath, _)):
            if indexPath.count < 2 {
                self.tableView?.insertSections(NSIndexSet(index: indexPath[0]), withRowAnimation: .Fade)
            } else {
                let indexPath = NSIndexPath(forRow: indexPath[0], inSection: indexPath[1])
                self.tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .Update(let (indexPath, _)):
            if indexPath.count < 2 {
                self.tableView.reloadSections(NSIndexSet(index: indexPath[0]), withRowAnimation: .Fade)
            } else {
                let indexPath = NSIndexPath(forRow: indexPath[1], inSection: indexPath[0])
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            
        case .Composite(let changes):
            self.tableView.beginUpdates()
            changes.forEach { self.handleChange($0) }
            self.tableView.endUpdates()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.disposables += self.viewModel.files.changes.startWithNext { [weak self] in
            self?.handleChange($0)
        }
        
    }
    
    func configureCellFunc(cell: UITableViewCell, populateWith object: NSManagedObject) {
        switch (cell, object) {
        case let (cell, file as File):
            cell.textLabel?.text = file.id.stringValue
            break
        default:
            break
        }
    }
    
}

extension FilesViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.viewModel.files.value.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.files.value[section].value.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let file = self.viewModel.files[indexPath.section][indexPath.row]
        self.configureCellFunc(cell, populateWith: file)
        return cell
    }
    
}
