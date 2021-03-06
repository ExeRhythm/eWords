//
//  CollectionsViewCell.swift
//  eWords
//
//  Created by iMac on 22.03.2020.
//  Copyright © 2020 iMac. All rights reserved.
//

import UIKit

class CollectionsViewCell: UICollectionViewCell {
    @IBOutlet weak var nameOfCollectionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var bgView: RoundedButtonWithShadow!
    
    override var isHighlighted:Bool{
        didSet{
            if(isHighlighted == true){
                self.bgView.backgroundColor = .lightGray
            } else {
                self.bgView.backgroundColor = UIColor(named: "Color")
            }
        }
    }
}
