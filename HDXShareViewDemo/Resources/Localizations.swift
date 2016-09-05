
import Foundation

func tr(key: String, _ args: [CVarArgType] = []) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, locale: NSLocale.currentLocale(), arguments: args)
}

struct Localizations {
	/// 微信好友
	static var ShareWXFriend: String = tr("share-WX-friend")
	/// 朋友圈
	static var ShareWXTimeline: String = tr("share-WX-timeline")
	/// QQ 好友
	static var ShareQQFriend: String = tr("share-QQ-friend")
	/// QQ 空间
	static var ShareQQZone: String = tr("share-QQ-zone")
	/// 微博
	static var ShareWeibo: String = tr("share-weibo")
}
