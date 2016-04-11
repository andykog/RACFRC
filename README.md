# RACFRC

Proof of concept for using NSFetchedResultsController with [RAC-MutableCollectionProperty](https://github.com/gitdoapp/RAC-MutableCollectionProperty)


## How to use

* Create instance of RACFRC [like this](RACFRCTests/FilesViewModel.swift#L44)
* Use `files.changes` signal producer as you want ([example](RACFRCTests/FilesViewController.swift#L54))


## TODO:

* Framework with Carthage/cocoapods support
