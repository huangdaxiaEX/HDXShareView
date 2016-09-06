
A shareView like Weibo animation when write weibo, provide some functions to callback.

# Tools 

* MonkeyKing

  Learn from the [`MonkeyKing`](https://github.com/nixzhu/MonkeyKing)  inspiration and some code to write `ShareController`

* SwiftGen

  Use `SwiftGen` to write Xcode script to product `Loczilation.swift` and `Images.swift`
  
* Alamofire

  Use `Alamofire` to send request to other apps

* CocoaPods Carthage
 
  Manage project SDK


# Guide

    let shareModel = ShareModel(title: "share title", description: "share title", thumbnail: Images.ShareQQ, media: .URL(URL))
          let shareView = HDXShareView(shareModel: shareModel) {
            print("share finished")
        }
    shareView.show()


