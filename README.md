# RACFRC

Proof of concept for using NSFetchedResultsController with [RAC-MutableCollectionProperty](https://github.com/gitdoapp/RAC-MutableCollectionProperty)


## How to use

* Copy code (for now)
* Create instance of RACFRC:
```swift
class FilesViewModel {

    lazy var files: MutableCollectionProperty<RACFRCSection<File>> = MutableCollectionProperty([])
    
    lazy var frc: NSFetchedResultsController? = {
        guard let moc = AuthService.userStorage?.managedObjectContext else { return nil }
        
        NSFetchedResultsController.deleteCacheWithName("Files")
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("File", inManagedObjectContext: moc)
        fetchRequest.returnsObjectsAsFaults = true // <!>
        fetchRequest.fetchBatchSize = 30
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        fetchRequest.predicate = NSPredicate(value: true)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "Files")
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            return nil
        }
        
        return fetchedResultsController
    }()
    
    lazy var frcBridge: RACFRC = RACFRC(frc: self.frc, property: self.files)
    
    init() {
        
    }

}
```

Use `files.changes` signal producer as you want. For example:


```swift
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
        case let (cell as UITableViewCell, file as File):
            cell.textLabel?.text = file.fileName
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
```



## TODO:

* Make it as a usable library
