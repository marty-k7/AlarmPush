//
//  AlarmViewController.swift
//  AlarmPush
//
//  Created by Martynas Klastaitis  on 02/04/2019.
//  Copyright © 2019 bajoraiciuprodukcija. All rights reserved.
//

import UIKit

class AlarmViewController: UITableViewController {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var caption: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tapToSelectImage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
    }
    @IBAction func imageViewTapped(_ sender: UITapGestureRecognizer) {
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
