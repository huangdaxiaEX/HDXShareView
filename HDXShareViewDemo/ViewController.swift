//
//  ViewController.swift
//  HDXShareViewDemo
//
//  Created by huangdaxia on 16/9/5.
//  Copyright © 2016年 huangdaxia. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = .grayColor()
        
        let button = UIButton()
        button.frame = CGRect(x: 40, y: 40, width: 100, height: 100)
        button.backgroundColor = .orangeColor()
        button.addTarget(self, action: #selector(didClickButton), forControlEvents: .TouchUpInside)
        view.addSubview(button)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didClickButton() {
        let URL = NSURL(string: "https://developer.apple.com/")!
        let shareModel = ShareModel(title: "share title", description: "share title", thumbnail: Images.ShareQQ, media: .URL(URL))
        let shareView = HDXShareView(shareModel: shareModel) {
            print("share finished")
        }
        shareView.show()
    }
    
}

