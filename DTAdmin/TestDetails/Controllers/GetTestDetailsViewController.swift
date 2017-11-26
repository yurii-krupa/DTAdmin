//
//  getTestDetailsViewController.swift
//  DTAdmin
//
//  Created by ITA student on 11/17/17.
//  Copyright © 2017 if-ios-077. All rights reserved.
//

import UIKit

class GetTestDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let dataModel = DataModel.dataModel
    @IBOutlet weak var tableView: UITableView!
    var testDetailForSave: TestDetailStructure?
    var resultModification: ((TestDetailStructure) -> ())?
    var canEdit = Bool()
    var idForEditing = String()
    var id = "3"
    var maxTask = Int()
    var testDetailsInstance: TestDetailStructure? {
        didSet {
            self.view.layoutIfNeeded()
            guard let detailsLevel = testDetailsInstance?.level,
                let detailsTask = testDetailsInstance?.tasks, 
                let detailsRate = testDetailsInstance?.rate else { return }
            dataModel.detailArray[0].number = detailsLevel
            dataModel.detailArray[1].number = detailsTask
            dataModel.detailArray[2].number = detailsRate
            DispatchQueue.main.async {
                if self.canEdit {
                    self.title = "Editing"
                    guard let testDetailId = self.testDetailsInstance?.id else { return }
                    self.idForEditing = testDetailId
                    self.tableView.reloadData()
                } else {
                    return
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Creating"
        var array = [DetailStructure]()
        for i in dataModel.details {
            array.append(DetailStructure(detail: i, number: "0"))
        }
        dataModel.detailArray = array
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataModel.detailArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let prototypeCell = tableView.dequeueReusableCell(withIdentifier: "selectDetailsCell",
                                                          for: indexPath) as? SelectDetailsTableViewCell
        guard let cell = prototypeCell else { return UITableViewCell() }
        cell.testDetailNameLabel.text = dataModel.detailArray[indexPath.row].detail
        cell.numberOfTestDetailLabel.text = dataModel.detailArray[indexPath.row].number
        cell.numberOfTestDetailLabel.alpha = 0.5
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let numbersViewController = UIStoryboard(name: "TestDetails",
                                                              bundle: nil).instantiateViewController(
        withIdentifier: "NumbersViewController") as? NumbersViewController else { return }
        numbersViewController.detail = indexPath.row
        numbersViewController.result = { result in
            if result != 0 {
                self.dataModel.detailArray[indexPath.row].number = String(result)
                self.tableView.reloadData()
            } else {
                return
            }
        }
        dataModel.currentDataForSelecting()
        self.navigationController?.pushViewController(numbersViewController, animated: true)
    }

    /**
     This function get data from table view for creation new text detail item.
     - Precondition: All test details have to have its property value.
     - Postcondition: Test detail item is prepared to request to API.
     - Returns: This function returns true - when all test details property value are selected or false - when not
     */
    func prepareForRequest() -> Bool {
        let level = dataModel.detailArray[0].number
        let task = dataModel.detailArray[1].number
        let rate = dataModel.detailArray[2].number
        if level != "0" && task != "0" && rate != "0" {
            let dictionary: [String: Any] = ["test_id": id, "level": level, "tasks": task, "rate": rate]
            self.testDetailForSave = TestDetailStructure(dictionary: dictionary)
            return true
        } else {
            return false
        }
    }

    @IBAction func CreateSpecialityButton(_ sender: Any) {
        !canEdit ? createTestDetail() : updateTestDetail()
    }

    func createTestDetail() {
        if prepareForRequest() {
            guard let testDetailForSave = testDetailForSave else { return }
            DataManager.shared.insertEntity(entity: testDetailForSave, typeEntity: .testDetail) { (result, error) in
                if let error = error {
                    self.showWarningMsg(error)
                    return
                } else {
                    guard let result = result as? [[String : Any]] else { return }
                    guard let firstResult = result.first else { return }
                    guard let testDetailResult = TestDetailStructure(dictionary: firstResult) else { return }
                    if let resultModification = self.resultModification {
                        resultModification(testDetailResult)
                    }
                }
            }
            self.navigationController?.popViewController(animated: true)
        } else {
            showWarningMsg(NSLocalizedString("Incorrect data. All fields have to be filled",
                                             comment: "All fields have to be filled"))
        }
    }

    func updateTestDetail() {
        if prepareForRequest() {
            guard let testDetailForSave = testDetailForSave else { return }
            DataManager.shared.updateEntity(byId: idForEditing,
                entity: testDetailForSave, typeEntity: .testDetail) { (error) in
                    if let error = error {
                        self.showWarningMsg(error)
                        return
                    } else {
                        if let resultModification = self.resultModification {
                            testDetailForSave.id = self.idForEditing
                            resultModification(testDetailForSave)
                        }
                    }
            }
            self.navigationController?.popViewController(animated: true)
        } else {
            showWarningMsg(NSLocalizedString("Incorrect data. All fields have to be filled",
                                             comment: "All fields have to be filled"))
        }
    }

    
}