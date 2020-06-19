//
//  ViewController.swift
//  FetchedResultsControllerExperiments
//
//  Created by Joseph Lord on 18/06/2020.
//  Copyright © 2020 Joseph Lord. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    let button = UIButton(type: .infoDark)
    let datasource = Datasource(tableView: UITableView())
    override func viewDidLoad() {
        super.viewDidLoad()
        let tableView = datasource.tableView
        self.view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addConstraints([
            NSLayoutConstraint(item: tableView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0),
        ])
        view.addSubview(button)
        view.addConstraints([
            NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: tableView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        ])
        button.addTarget(self, action: #selector(shuffleItems), for: .primaryActionTriggered)
        deleteAll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datasource.load()
        createItems()
    }

    func createItems() {
        let context = mainContext
        let entities = (1...3).map { (order: Int32) -> Entity in
            let entity = Entity(entity: Entity.entity(), insertInto: context)
            entity.creationDate = Date().timeIntervalSince1970
            entity.order = order
            return entity
        }
        entities[0].label = "First"
        entities[1].label = "Second"
        entities[2].label = "Third"
    }

    func deleteAll() {
        let all = try! mainContext.fetch(fetchRequest)
        all.forEach { mainContext.delete($0) }
        try! mainContext.save()
    }

    @objc func shuffleItems() {
        backgroundQueue.async {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.parent = mainContext
            do {
                let objects = try context.fetch(fetchRequest)
                zip(objects, [2,1,3]).forEach { entity, newIndex in
                    entity.order = newIndex
                }
                try context.save()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    let backgroundQueue = DispatchQueue(label: "background")
}

let mainContext = AppDelegate.persistentContainer.viewContext
let fetchRequest: NSFetchRequest<Entity> = {
    let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    return fetchRequest
}()

class Datasource : NSObject, NSFetchedResultsControllerDelegate {

    lazy var diffableDataSource = UITableViewDiffableDataSource<String, NSManagedObjectID>(
        tableView: tableView,
        cellProvider: { [weak self] tableView, indexPath, id in
            guard let entity = self?.controller.object(at: indexPath) else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "\(entity.order) \(entity.label!)"
            return cell
    })
    init(tableView: UITableView) {
        controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.tableView = tableView
        super.init()
        controller.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    func load() {
        try! controller.performFetch()
        tableView.dataSource = diffableDataSource
    }

    let controller: NSFetchedResultsController<Entity>
    let tableView: UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller.fetchedObjects!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entity = controller.fetchedObjects![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(entity.order) \(entity.label!)"
        return cell
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.diffableDataSource.apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>)
    }

//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.beginUpdates()
//        print("begin")
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
//        assertionFailure()
//        return sectionName
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        assertionFailure(sectionInfo.indexTitle!.description)
//
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch (type) {
//        case NSFetchedResultsChangeType.insert:
//            if let actNewIndexPath = newIndexPath {
//                tableView.insertRows(at: [actNewIndexPath], with: .automatic)
//                print("insert: \(actNewIndexPath.row)")
//            }
//        case NSFetchedResultsChangeType.delete:
//            if let actIndexPath = indexPath {
//                tableView.deleteRows(at: [actIndexPath], with: .fade)
//                print("delete: \(actIndexPath.row)")
//            }
//        case NSFetchedResultsChangeType.update:
//            if let actIndexPath = indexPath {
//                tableView.reloadRows(at: [actIndexPath], with: .fade)
//                print("update: \(actIndexPath.row)")
//            }
//        case NSFetchedResultsChangeType.move:
//            if let indexPath = indexPath, let newIndexPath = newIndexPath {
//                tableView.moveRow(at: indexPath, to: newIndexPath)
//                print("move: \(indexPath.row) -> \(newIndexPath.row)")
//            } else { assertionFailure() }
//        @unknown default:
//            assertionFailure()
//        }
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        print("end")
//        tableView.endUpdates()
//    }

}

