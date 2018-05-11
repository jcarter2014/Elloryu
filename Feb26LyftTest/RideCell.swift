//
//  RideCell.swift
//  Feb26LyftTest
//
//  Created by John Carter on 3/26/18.
//  Copyright © 2018 Jack Carter. All rights reserved.
//

import UIKit

class RideCell: UITableViewCell {

    @IBOutlet weak var rideType: UILabel!
    @IBOutlet weak var ridePrice: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
