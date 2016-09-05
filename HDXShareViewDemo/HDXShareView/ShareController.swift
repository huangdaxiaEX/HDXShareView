//
//  ShareController.swift
//  HDXShareViewDemo
//
//  Created by huangdaxia on 16/9/5.
//  Copyright © 2016年 huangdaxia. All rights reserved.
//

import UIKit

struct Config {
    static let WeChatID = ""
    static let WeChatKey = ""
    static let TXQQID = ""
    static let TXQQKey = ""
    static let WeiboID = ""
}

struct ShareModel {
    var title: String?
    var description: String?
    var thumbnail: UIImage?
    var media: ShareController.Media?
}

final class ShareController {
    typealias ShareCompletionHandler = (result: Bool) -> Void
    
    private var shareCompletionHandler: ShareCompletionHandler?
    
    private init() {}
    private static let instance = ShareController()
    
    class func shareInfoWithShareModel(shareModel: ShareModel) -> ShareInfo {
        return ShareInfo(title: shareModel.title,
                         description: shareModel.description,
                         thumbnail: shareModel.thumbnail,
                         media: shareModel.media)
    }
    
}


// MARK: Target Apps

extension ShareController {
    enum TargetApp {
        case WeChat
        case TXQQ
        case Weibo
        
        var isInstalled: Bool {
            switch self {
            case .WeChat:
                return ShareController.canOpenURL(URLString: "weixin://")
            case .TXQQ:
                return ShareController.canOpenURL(URLString: "mqqapi://")
            case .Weibo:
                return ShareController.canOpenURL(URLString: "weibosdk://request")
            }
        }
        
        var canWebOAuth: Bool {
            return true
        }
    }
    
}

// MARK: Handle URL

extension ShareController {
    private class func canOpenURL(URLString URL: String) -> Bool {
        guard let URL = NSURL(string: URL) else {
            return false
        }
        
        return UIApplication.sharedApplication().canOpenURL(URL)
    }
    
    private class func openURL(URLString URLString: String) -> Bool {
        guard let URL = NSURL(string: URLString) else {
            return false
        }
        
        return UIApplication.sharedApplication().openURL(URL)
    }
    
    class func handleOpenURL(URL: NSURL) -> Bool {
        if URL.scheme.hasPrefix("wx") {
            guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("content") else {
                return false
            }
            if let dic = try? NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil) {
                guard let dic = dic[Config.WeChatID] as? NSDictionary, result = dic["result"]?.integerValue else {
                    return false
                }
                
                let success = (result == 0)
                instance.shareCompletionHandler?(result: success)
                
                return success
            }
        }
        
        if URL.scheme.hasPrefix("QQ") {
            guard let error = URL.queryDictionary["error"] as? String else {
                return false
            }
            
            let success = (error == "0")
            
            instance.shareCompletionHandler?(result: success)
            
            return success
        }
        
        if URL.scheme.hasPrefix("wb") {
            guard let items = UIPasteboard.generalPasteboard().items as? [[String: AnyObject]] else {
                return false
            }
            var results = [String: AnyObject]()
            for item in items {
                for (key, value) in item {
                    if let valueData = value as? NSData where key == "transferObject" {
                        results[key] = NSKeyedUnarchiver.unarchiveObjectWithData(valueData)
                    }
                }
            }
            guard let responseData = results["transferObject"] as? [String: AnyObject],
                let type = responseData["__class"] as? String else {
                    return false
            }
            guard let statusCode = responseData["statusCode"] as? Int else {
                return false
            }
            
            switch type {
            case "WBSendMessageToWeiboResponse":
                let success = (statusCode == 0)
                instance.shareCompletionHandler?(result: success)
                
                return success
                
            default:
                break
            }
        }
        
        return false
    }
    
}

// MARK: Share info
extension ShareController {
    typealias ShareInfo = (title: String?, description: String?, thumbnail: UIImage?, media: Media?)
    
    enum Media {
        case URL(NSURL)
        case Image(UIImage)
        case Audio(audioURL: NSURL, linkURL: NSURL?)
        case Video(NSURL)
        case File(NSData)
    }
    
    enum Message {
        case WeChat(WeChatSubType)
        case TXQQ(QQSubType)
        case Weibo(WeiboSubType)
        
        var canBeDelivered: Bool {
            switch self {
            case .WeChat(_):
                return TargetApp.WeChat.isInstalled
            case .TXQQ(_):
                return TargetApp.TXQQ.isInstalled
            case .Weibo(_):
                return TargetApp.Weibo.isInstalled
            }
        }
        
        // MARK: WeChatSubType
        
        enum WeChatSubType {
            case Session(shareInfo: ShareInfo)
            case Timeline(shareInfo: ShareInfo)
            case Favorite(shareInfo: ShareInfo)
            
            var scene: String {
                switch self {
                case .Session:
                    return "0"
                case .Timeline:
                    return "1"
                case .Favorite:
                    return "2"
                }
            }
            
            var shareInfo: ShareInfo {
                switch self {
                case .Session(let info):
                    return info
                case .Timeline(let info):
                    return info
                case .Favorite(let info):
                    return info
                }
            }
        }
        
        // MARK: QQSubType
        
        enum QQSubType {
            case Friends(shareInfo: ShareInfo)
            case Zone(shareInfo: ShareInfo)
            case Favorite(shareInfo: ShareInfo)
            case Dataline(shareInfo: ShareInfo)
            
            var scene: Int {
                switch self {
                case .Friends:
                    return 0x00
                case .Zone:
                    return 0x01
                case .Favorite:
                    return 0x08
                case .Dataline:
                    return 0x10
                }
            }
            
            var shareInfo: ShareInfo {
                switch self {
                case .Friends(let info):
                    return info
                case .Zone(let info):
                    return info
                case .Favorite(let info):
                    return info
                case .Dataline(let info):
                    return info
                }
            }
        }
        
        // MARK: WeiboSubType
        
        enum WeiboSubType {
            case Default(shareInfo: ShareInfo, AccessToken: String?)
            
            var shareInfo: ShareInfo {
                switch self {
                case .Default(let info, _):
                    return info
                }
            }
            
            var accessToken: String? {
                switch self {
                case .Default(_, let accessToken):
                    return accessToken
                }
            }
        }
    }
    
}


// MARK: Share message

extension ShareController {
    class func shareMessage(message: Message, shareCompletionHandler: ShareCompletionHandler) {
        guard message.canBeDelivered else {
            shareCompletionHandler(result: false)
            return
        }
        
        instance.shareCompletionHandler = shareCompletionHandler
        switch message {
        case .WeChat(let type):
            weChatMessage(type, shareCompletionHandler: shareCompletionHandler)
        case .TXQQ(let type):
            qqMessage(type, shareCompletionHandler: shareCompletionHandler)
        case .Weibo(let type):
            weiboMessage(type, shareCompletionHandler: shareCompletionHandler)
        }
    }
    
    // MARK: WeChat message
    
    private class func weChatMessage(type: Message.WeChatSubType, shareCompletionHandler: ShareCompletionHandler) {
        var weChatMessageInfo: [String: AnyObject] = [
            "result": "1",
            "returnFromApp": "0",
            "scene": type.scene,
            "sdkver": "1.5",
            "command": "1010"
        ]
        
        let shareInfo = type.shareInfo
        if let title = shareInfo.title {
            weChatMessageInfo["title"] = title
        }
        if let description = shareInfo.description {
            weChatMessageInfo["description"] = description
        }
        if let thumbnailData = shareInfo.thumbnail?.compressedImageData {
            weChatMessageInfo["thumbData"] = thumbnailData
        }
        if let media = shareInfo.media {
            switch media {
            case .URL(let URL):
                weChatMessageInfo["objectType"] = "5"
                weChatMessageInfo["mediaUrl"] = URL.absoluteString
            case .Image(let image):
                weChatMessageInfo["objectType"] = "2"
                if let fileImageData = UIImageJPEGRepresentation(image, 1) {
                    weChatMessageInfo["fileData"] = fileImageData
                }
            case .Audio(let audioURL, let linkURL):
                weChatMessageInfo["objectType"] = "3"
                if let linkURL = linkURL {
                    weChatMessageInfo["mediaUrl"] = linkURL.absoluteString
                }
                weChatMessageInfo["mediaDataUrl"] = audioURL.absoluteString
            case .Video(let URL):
                weChatMessageInfo["objectType"] = "4"
                weChatMessageInfo["mediaUrl"] = URL.absoluteString
            case .File(_):
                fatalError("WeChat not supports File type")
            }
        } else {
            weChatMessageInfo["command"] = "1020"
        }
        
        let weChatMessage = [Config.WeChatID : weChatMessageInfo]
        guard let data = try? NSPropertyListSerialization.dataWithPropertyList(weChatMessage, format: .BinaryFormat_v1_0, options: 0) else {
            return
        }
        
        UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "content")
        let weChatSchemeURLString = "weixin://app/\(Config.WeChatID)/sendreq/?"
        
        if !openURL(URLString: weChatSchemeURLString) {
            shareCompletionHandler(result: false)
        }
        
    }
    
    // MARK: QQ message
    
    private class func qqMessage(type: Message.QQSubType, shareCompletionHandler: ShareCompletionHandler) {
        let callbackName = Config.TXQQID.qqCallbackName
        var qqSchemeURLString = "mqqapi://share/to_fri?"
        if let encodedAppDisplayName = NSBundle.mainBundle().dislayName?.base64EncodedString {
            qqSchemeURLString += "thirdAppDisplayName=" + encodedAppDisplayName
        } else {
            qqSchemeURLString += "thirdAppDisplayName=" + "Ym9uZw=="
        }
        qqSchemeURLString += "&version=1&cflag=\(type.scene)"
        qqSchemeURLString += "&callback_type=scheme&generalpastboard=1"
        qqSchemeURLString += "&callback_name=\(callbackName)"
        qqSchemeURLString += "&src_type=app&shareType=0&file_type="
        if let media = type.shareInfo.media {
            func handleNewsWithURL(URL: NSURL, mediaType: String?) {
                if let thumbnail = type.shareInfo.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                    let dic = ["previewimagedata": thumbnailData]
                    let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                    UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                }
                
                qqSchemeURLString += mediaType ?? "news"
                
                guard let encodedURLString = URL.absoluteString.base64AndURLEncodedString else {
                    shareCompletionHandler(result: false)
                    return
                }
                
                qqSchemeURLString += "&url=\(encodedURLString)"
            }
            switch media {
            case .URL(let URL):
                handleNewsWithURL(URL, mediaType: "news")
            case .Image(let image):
                guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                    shareCompletionHandler(result: false)
                    return
                }
                var dic = ["file_data": imageData]
                if let thumbnail = type.shareInfo.thumbnail, thumbnailData = UIImageJPEGRepresentation(thumbnail, 1) {
                    dic["previewimagedata"] = thumbnailData
                }
                let data = NSKeyedArchiver.archivedDataWithRootObject(dic)
                UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                qqSchemeURLString += "img"
            case .Audio(let audioURL, _):
                handleNewsWithURL(audioURL, mediaType: "audio")
            case .Video(let URL):
                handleNewsWithURL(URL, mediaType: nil)
            case .File(let fileData):
                let data = NSKeyedArchiver.archivedDataWithRootObject(["file_data": fileData])
                UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "com.tencent.mqq.api.apiLargeData")
                
                qqSchemeURLString += "localFile"
                
                if let filename = type.shareInfo.description?.URLEncodedString {
                    qqSchemeURLString += "&fileName=\(filename)"
                }
            } // switch end
            
            if let encodedTitle = type.shareInfo.title?.base64AndURLEncodedString {
                qqSchemeURLString += "&title=\(encodedTitle)"
            }
            
            if let encodedDescription = type.shareInfo.description?.base64AndURLEncodedString {
                qqSchemeURLString += "&objectlocation=pasteboard&description=\(encodedDescription)"
            }
        } else {
            qqSchemeURLString += "text&file_data="
            if let encodedDescription = type.shareInfo.description?.base64AndURLEncodedString {
                qqSchemeURLString += "\(encodedDescription)"
            }
        } // media end
        
        if !openURL(URLString: qqSchemeURLString) {
            shareCompletionHandler(result: false)
        }
        
    }
    
    //MARK: Weibo message
    
    private class func weiboMessage(type: Message.WeiboSubType, shareCompletionHandler: ShareCompletionHandler) {
        guard !canOpenURL(URLString: "weibosdk://request") else {
            var messageInfo: [String: AnyObject] = ["__class": "WBMessageObject"]
            let shareInfo = type.shareInfo
            
            if let description = shareInfo.description {
                messageInfo["text"] = description
            }
            
            if let media = shareInfo.media {
                switch media {
                case .URL(let URL):
                    var mediaObject: [String: AnyObject] = [
                        "__class": "WBWebpageObject",
                        "objectID": "identifier1"
                    ]
                    if let title = shareInfo.title {
                        mediaObject["title"] = title
                    }
                    if let thumbnailImage = shareInfo.thumbnail,
                        let thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.7) {
                        mediaObject["thumbnailData"] = thumbnailData
                    }
                    mediaObject["webpageUrl"] = URL.absoluteString
                    messageInfo["mediaObject"] = mediaObject
                case .Image(let image):
                    if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                        messageInfo["imageObject"] = ["imageData": imageData]
                    }
                case .Audio:
                    fatalError("Weibo not supports Audio type")
                case .Video:
                    fatalError("Weibo not supports Video type")
                case .File:
                    fatalError("Weibo not supports File type")
                }
            }
            
            let uuIDString = CFUUIDCreateString(nil, CFUUIDCreate(nil))
            let dict = ["__class" : "WBSendMessageToWeiboRequest", "message": messageInfo, "requestID" :uuIDString]
            
            let messageData: [AnyObject] = [
                ["transferObject": NSKeyedArchiver.archivedDataWithRootObject(dict)],
                ["app": NSKeyedArchiver.archivedDataWithRootObject(["appKey": Config.WeiboID, "bundleID": NSBundle.mainBundle().bundleID ?? ""])]
            ]
            UIPasteboard.generalPasteboard().items = messageData
            if !openURL(URLString: "weibosdk://request?id=\(uuIDString)&sdkversion=003013000") {
                shareCompletionHandler(result: false)
            }
            return // guard end
        }
        
        // weibo share
        let info = type.shareInfo
        var parameters = [String: AnyObject]()
        guard let accessToken = type.accessToken else {
            print("When Weibo did not install, accessToken must need")
            shareCompletionHandler(result: false)
            return
        }
        parameters["access_token"] = accessToken
        var statusText = ""
        if let title = info.title {
            statusText += title
        }
        if let description = info.description {
            statusText += description
        }
        var mediaType = Media.URL(NSURL())
        if let media = info.media {
            switch media {
            case .URL(let URL):
                statusText += URL.absoluteString
                mediaType = Media.URL(URL)
            case .Image(let image):
                guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
                    shareCompletionHandler(result: false)
                    return
                }
                parameters["pic"] = imageData
                mediaType = Media.Image(image)
            case .Audio:
                fatalError("web Weibo not supports Audio type")
            case .Video:
                fatalError("web Weibo not supports Video type")
            case .File:
                fatalError("web Weibo not supports File type")
            }
        }
        
        parameters["status"] = statusText
        switch mediaType {
        case .URL(_):
            let URLString = "https://api.weibo.com/2/statuses/update.json"
            Alamofire.request(.POST, URLString, parameters: parameters, encoding: .JSON).responseJSON(completionHandler: { (responseData) in
                if let JSON = responseData.result.value, let _ = JSON["idstr"] as? String {
                    shareCompletionHandler(result: true)
                } else {
                    log.error("response data error")
                    shareCompletionHandler(result: false)
                }
            })
        case .Image(_):
            let URLString = "https://upload.api.weibo.com/2/statuses/upload.json"
            Alamofire.request(.POST, URLString, parameters: parameters, encoding: .JSON).responseJSON(completionHandler: { (responseData) in
                if let JSON = responseData.result.value, let _ = JSON["idstr"] as? String {
                    shareCompletionHandler(result: true)
                } else {
                    log.error("response data error")
                    shareCompletionHandler(result: false)
                }
            })
        case .Audio:
            fatalError("web Weibo not supports Audio type")
        case .Video:
            fatalError("web Weibo not supports Video type")
        case .File:
            fatalError("web Weibo not supports File type")
        }
    }
    
}

// MARK: Private extension

private extension UIImage {
    var compressedImageData: NSData? {
        var compressionQuality: CGFloat = 0.7
        
        func compressImage(image: UIImage) -> NSData? {
            let maxHeight: CGFloat = 240
            let maxWidth: CGFloat = 240
            var actualHeight: CGFloat = image.size.height
            var actualWidth: CGFloat = image.size.width
            var imageRatio: CGFloat = actualWidth / actualHeight
            let maxRatio: CGFloat = maxWidth / maxHeight
            
            if actualHeight > maxHeight || actualWidth > maxWidth {
                if imageRatio < maxRatio {
                    imageRatio = maxHeight / actualHeight
                    actualWidth = imageRatio * actualWidth
                    actualHeight = maxHeight
                } else if imageRatio > maxRatio {
                    imageRatio = maxWidth / actualWidth
                    actualHeight = imageRatio * actualHeight
                    actualWidth = maxWidth
                } else {
                    actualHeight = maxHeight
                    actualWidth = maxWidth
                }
            }
            let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
            UIGraphicsBeginImageContext(rect.size)
            image.drawInRect(rect)
            let imageData = UIImageJPEGRepresentation(UIGraphicsGetImageFromCurrentImageContext(), compressionQuality)
            UIGraphicsEndImageContext()
            
            return imageData
        }
        
        var imageData = UIImageJPEGRepresentation(self, compressionQuality)
        
        guard imageData != nil else {
            return nil
        }
        
        let minCompressionQuality: CGFloat = 0.01
        let dataLengthCeiling: Int = 31500
        
        while imageData!.length > dataLengthCeiling && compressionQuality > minCompressionQuality {
            compressionQuality -= 0.1
            guard let image = UIImage(data: imageData!) else {
                break
            }
            imageData = compressImage(image)
        }
        
        return imageData
    }
    
}

private extension String {
    var qqCallbackName: String {
        var hexString = String(format: "%02llx", (self as NSString).longLongValue)
        while hexString.characters.count < 8 {
            hexString = "0" + hexString
        }
        
        return "QQ" + hexString
    }
    
    var base64EncodedString: String? {
        return dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    var URLEncodedString: String? {
        return stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
    
    var base64AndURLEncodedString: String? {
        return base64EncodedString?.URLEncodedString
    }
    
}

private extension NSURL {
    var queryDictionary: [String: AnyObject] {
        var infos = [String: AnyObject]()
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)
        guard let items = components?.queryItems else {
            return infos
        }
        items.forEach {
            infos[$0.name] = $0.value
        }
        
        return infos
    }
    
}

private extension NSBundle {
    var dislayName: String? {
        func getNameByInfo(info: [String : AnyObject]) -> String? {
            guard let displayName = info["CFBundleDisplayName"] as? String else {
                return info["CFBundleName"] as? String
            }
            return displayName
        }
        var info = infoDictionary
        if let localizedInfo = localizedInfoDictionary where !localizedInfo.isEmpty {
            info = localizedInfo
        }
        guard let unwrappedInfo = info else {
            return nil
        }
        
        return getNameByInfo(unwrappedInfo)
    }
    
    var bundleID: String? {
        return objectForInfoDictionaryKey("CFBundleIdentifier") as? String
    }
    
}