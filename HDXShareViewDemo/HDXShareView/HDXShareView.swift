//
//  HDXShareView.swift
//  HDXShareViewDemo
//
//  Created by huangdaxia on 16/9/5.
//  Copyright © 2016年 huangdaxia. All rights reserved.
//

import UIKit
import Cartography

class HDXShareView: UIView {
    let shareItem: [ShareItem] = [.WeChatFriend, .WeChatTimeline, .Weibo, .QQFriend, .QQZone]
    let shareItemsViewHeight: CGFloat = 300
    var shareCompletionHandler: (() -> Void)?
    var shareModel: ShareModel?
    
    let size = UIScreen.mainScreen().bounds.size
    
    lazy var shareCollectionView: UICollectionView = { [unowned self] in
        let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectView.dataSource = self
        collectView.delegate = self
        collectView.registerClass(ShareCollectionViewCell.self, forCellWithReuseIdentifier: ShareCollectionViewCell.identifier)
        collectView.backgroundColor = UIColor.clearColor()
        collectView.showsVerticalScrollIndicator = false
        collectView.scrollEnabled = false
        
        return collectView
        } ()
    
    let effectView: UIVisualEffectView = {
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        effect.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        
        return effect
    } ()
    
    init(shareModel: ShareModel? = nil, shareCompletionHandler: (() -> Void)? = nil) {
        self.shareModel = shareModel
        self.shareCompletionHandler = shareCompletionHandler
        super.init(frame: UIScreen.mainScreen().bounds)
        backgroundColor = .clearColor()
        addSubview(effectView)
        addSubview(shareCollectionView)
        
        setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        constrain(effectView, shareCollectionView, self) { (effect, collectView, superview) in
            effect.edges == inset(superview.edges, 0, 0, 0, 0)
            
            collectView.left == superview.left
            collectView.right == superview.right
            collectView.bottom == superview.bottom
            collectView.height == shareItemsViewHeight
        }
    }
    
    func show(inView view: UIView? = nil) {
        let root = view ?? UIApplication.sharedApplication().keyWindow
        root?.addSubview(self)
        
        shareCollectionView.alpha = 0
        UIView.animateWithDuration(0.25) {
            self.shareCollectionView.alpha = 1
        }
        
        shareCollectionView.reloadData()
    }
    
    func dismiss() {
        var rect = shareCollectionView.frame
        rect.origin.y += shareItemsViewHeight
        UIView.animateWithDuration(0.5, animations: {
            self.shareCollectionView.frame = rect
        }) { (finished) in
            self.removeFromSuperview()
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismiss()
    }
    
}

// MARK: UICollectionViewDataSource

extension HDXShareView: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return shareItem.count
        default:
            return 2
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ShareCollectionViewCell.identifier, forIndexPath: indexPath) as? ShareCollectionViewCell else {
            fatalError("cell is nil")
        }
        if indexPath.section == 1 {
            cell.config(.Cancel)
            cell.button.shareHandler = (nil, { [unowned self] in
                self.dismiss()
                })
        } else {
            let item = shareItem[indexPath.row]
            cell.config(item)
            cell.button.shareHandler = (shareModel, shareCompletionHandler)
        }
        
        cell.translateHeight(shareItemsViewHeight)
        cell.animation(CFTimeInterval(indexPath.row % 3))
        
        return cell
    }
    
}

// MARK: UICollectionViewDelegateFlowLayout

extension HDXShareView: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: size.width / 3, height: 100)
        } else {
            return CGSize(width: size.width, height: 100)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
}

// MARK: UICollectionViewDelegate

extension HDXShareView: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
}

// MARK: collection cell

class ShareCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "ShareCollectionViewCell"
    
    let button = ShareButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor.clearColor()
        addSubview(button)
        setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        constrain(button, self) { (button, superview) in
            button.center == superview.center
            button.height == superview.height
            button.width == 65
        }
    }
    
    func config(item: ShareItem) {
        button.setTitle(item.itemTitle(), forState: .Normal)
        button.setImage(item.itemImage(), forState: .Normal)
        button.shareItem = item
    }
    
    func translateHeight(offsetY: CGFloat) {
        let trans = CGAffineTransformTranslate(transform, 0, offsetY)
        transform = trans
    }
    
    func animation(delay: CFTimeInterval) {
        UIView.animateWithDuration(0.25, delay: delay / 10, options: .AllowAnimatedContent, animations: {
            self.transform = CGAffineTransformIdentity
        }) { (finished) in
            let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
            shakeAnimation.duration = 0.5
            shakeAnimation.values = [0, -10, 8, -5, 3, 0]
            shakeAnimation.repeatCount = 1
            self.layer.addAnimation(shakeAnimation, forKey: "shakeAnimation")
        }
    }
    
}

// MARK: 分享按钮

class ShareButton: UIButton {
    let topMargin: CGFloat = 15
    private var shareItem: ShareItem?
    var shareHandler: (shareModel: ShareModel?, completion: (() -> Void)?)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.textAlignment = .Center
        titleLabel?.font = UIFont.systemFontOfSize(12)
        imageView?.contentMode = .ScaleAspectFit
        addTarget(self, action: #selector(shareItemClicked), forControlEvents: .TouchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func imageRectForContentRect(contentRect: CGRect) -> CGRect {
        let x = (CGRectGetWidth(contentRect) - 60) / 2
        let y = (CGRectGetHeight(contentRect) - 60) / 2
        
        return CGRect(x: x, y: y, width: 60, height: 60)
    }
    
    override func titleRectForContentRect(contentRect: CGRect) -> CGRect {
        let x = (CGRectGetWidth(contentRect) - 60) / 2
        let y = (CGRectGetHeight(contentRect) - 60) / 2
        
        return CGRect(x: x, y: y + 65, width: 60, height: 15)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.2
        animation.toValue = 1.3
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        self.layer.addAnimation(animation, forKey: "touchAnimation")
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        layer.removeAnimationForKey("touchAnimation")
    }
    
    @objc private func shareItemClicked() {
        if let `shareItem` = shareItem {
            switch shareItem {
            case .Cancel:
                shareHandler.completion?()
            default:
                shareItem.shareMessage(shareHandler.shareModel, completion: shareHandler.completion)
            }
        }
    }
    
}

// MARK: 枚举

enum ShareItem {
    case WeChatFriend
    case WeChatTimeline
    case Weibo
    case QQFriend
    case QQZone
    case Cancel
    
    func itemTitle() -> String {
        switch self {
        case .WeChatFriend:
            return Localizations.ShareWXFriend
        case .WeChatTimeline:
            return Localizations.ShareWXTimeline
        case .Weibo:
            return Localizations.ShareWeibo
        case .QQFriend:
            return Localizations.ShareQQFriend
        case .QQZone:
            return Localizations.ShareQQZone
        case .Cancel:
            return ""
        }
    }
    
    func itemImage() -> UIImage {
        switch self {
        case .WeChatFriend:
            return Images.ShareWechat
        case .WeChatTimeline:
            return Images.ShareTimeline
        case .Weibo:
            return Images.ShareWeibo
        case .QQFriend:
            return Images.ShareQQ
        case .QQZone:
            return Images.ShareZone
        case .Cancel:
            return Images.ShareClose
        }
    }
    
    func shareMessage(shareModel: ShareModel?, completion: (() -> Void)?) {
        guard let shareModel = shareModel else { return }
        let shareInfo = ShareController.shareInfoWithShareModel(shareModel)
        var message: ShareController.Message?
        switch self {
        case .WeChatFriend:
            message = ShareController.Message.WeChat(.Session(shareInfo: shareInfo))
        case .WeChatTimeline:
            message = ShareController.Message.WeChat(.Timeline(shareInfo: shareInfo))
        case .Weibo:
            message = ShareController.Message.Weibo(.Default(shareInfo: shareInfo, AccessToken: nil))
        case .QQFriend:
            message = ShareController.Message.TXQQ(.Friends(shareInfo: shareInfo))
        case .QQZone:
            message = ShareController.Message.TXQQ(.Zone(shareInfo: shareInfo))
        case .Cancel:
            completion?()
            return
        }
        
        ShareController.shareMessage(message!) { (result) in
            if result {
                completion?()
            }
        }
    }
    
}
