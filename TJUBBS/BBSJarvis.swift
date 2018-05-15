//
//  BBSJarvis.swift
//  TJUBBS
//
//  Created by Halcao on 2017/5/10.
//  Copyright © 2017年 twtstudio. All rights reserved.
//

import UIKit
import ObjectMapper
import PiwikTracker

struct BBSJarvis {
    static func login(username: String, password: String, failure: ((Error)->())? = nil, success:@escaping ()->()) {
        let para: [String : String] = ["username": username, "password": password]
        BBSBeacon.request(withType: .post, url: BBSAPI.login, parameters: para, failure: failure) { dict in
            if let data = dict["data"] as? [String: Any] {
                BBSUser.shared.uid = data["uid"] as? Int
                BBSUser.shared.group = data["group"] as? Int
                BBSUser.shared.token = data["token"] as? String
                BBSUser.shared.username = username
                // 用 UserDefaults 存起来 BBSUser.shared
                BBSUser.save()
            }
            success()
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/in"
            PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "Login", name: nil, value: nil)
        }
    }
    
    static func logout() {
        PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
        PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
        PiwikTracker.shared.appName = "bbs.tju.edu.cn/"
        PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "Logout", name: nil, value: nil)
    }
    
    static func register(parameters: [String : String], failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .post, url: BBSAPI.register, parameters: parameters, failure: failure, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = parameters["username"]!
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/up"
            PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "Register", name: nil, value: nil)
        })
    }
    
    static func getHome(uid: Int = 0, success: ((UserWrapper)->())?, failure: @escaping (Error)->()) {
        if uid == 0 {
            BBSBeacon.request(withType: .get, url: BBSAPI.home, parameters: nil, failure: failure) { dict in
                if let data = dict["data"] as? [String: Any], let wrapper = Mapper<UserWrapper>().map(JSON: data) {
                    BBSUser.load(wrapper: wrapper)
                    success?(wrapper)
                } else if let err = dict["err"] as? Int, err == 0 {
                    failure(BBSError.custom)
                }
            }
        } else {
            BBSBeacon.request(withType: .get, url: BBSAPI.home(uid: uid), parameters: nil, failure: failure) { dict in
                if let data = dict["data"] as? [String : Any], let wrapper = Mapper<UserWrapper>().map(JSON: data), let recent = data["recent"] as? [[String : Any]] {
                    wrapper.uid = uid
                    wrapper.recentThreads = Mapper<ThreadModel>().mapArray(JSONArray: recent)
                    success?(wrapper)
                } else if let err = dict["err"] as? Int, err == 0 {
                    failure(BBSError.custom)
                }
            }
        }
    }
    
    static func getAvatar(success:@escaping (UIImage)->(), failure: @escaping (Error)->()) {
        BBSBeacon.requestImage(url: BBSAPI.avatar, failure: failure, success: success)
    }
    
    static func setAvatar(image: UIImage, success:@escaping ()->(), failure: @escaping (Error)->()) {
        BBSBeacon.uploadImage(url: BBSAPI.setAvatar, image: image, failure: failure, success: { _ in
                success()
        })
    }
    
    static func setInfo(para: [String : String], success: @escaping ()->(), failure: @escaping (Error)->()) {
        BBSBeacon.request(withType: .put, url: BBSAPI.home, parameters: para, failure: failure) { dict in
            success()
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/user/me/edit"
            PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "profile", name: "PUT", value: nil)
        }
    }

    static func getForumList(failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.forumList, token: nil, parameters: nil, failure: failure, success: success)
    }
    
    static func getBoardList(forumID: Int, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.boardList(forumID: forumID), token: nil, parameters: nil, failure: failure, success: success)
    }
    
    static func getThreadList(boardID: Int, page: Int, type: String = "", failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        print("API:\(BBSAPI.threadList(boardID: boardID, page: page, type: type))")
        BBSBeacon.request(withType: .get, url: BBSAPI.threadList(boardID: boardID, page: page, type: type), parameters: nil, failure: failure, success: success)
    }

    //TODO: cache Homepage
    static func getIndex(failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.index, parameters: nil, failure: failure, success: success)
    }
    
    static func getThread(threadID: Int, page: Int, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.thread(threadID: threadID, page: page), parameters: nil, failure: failure, success: success)
    }

    
    static func postThread(boardID: Int, title: String, anonymous: Bool = false, content: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        var parameters = [
            "title": title,
            "content": content
        ]
        if anonymous == true {
            parameters["anonymous"] = "1"
        }
//        print("API:\(BBSAPI.postThread(boardID: boardID))")
//        print(parameters)
        BBSBeacon.request(withType: .post, url: BBSAPI.postThread(boardID: boardID), parameters: parameters, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/forum/board/\(boardID)/all/page/1/"
            PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "boardposting", name: "POST", value: nil)
        })
    }
    
//    static func getMsgList(page: Int, failure: ((Error)->())? = nil, success: @escaping ([MessageModel])->()) {
//        BBSBeacon.request(withType: .get, url: BBSAPI.reciveMessage(page: page), parameters: nil, success: success)
//    }
    

    static func reply(threadID: Int, content: String, toID: Int?, anonymous: Bool = false, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        var parameters = ["content": content]
        if let id = toID {
            parameters["reply"] = "\(id)"
        }
        if anonymous == true {
            parameters["anonymous"] = "1"
        }
        BBSBeacon.request(withType: .post, url: BBSAPI.reply(threadID: threadID), parameters: parameters, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/forum/thread/\(threadID)/page/1/"
            PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "comment", name: "POST", value: nil)
        })
    }
    
    static func getMessageCount(failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.messageCount, parameters: nil, failure: failure, success: success)
    }
    
    static func setMessageRead(failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .post, url: BBSAPI.messageRead, parameters: nil, failure: failure, success: success)
    }
    
    static func getMessage(page: Int, failure: ((Error)->())? = nil, success: @escaping ([MessageModel])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.message(page: page), parameters: nil, failure: failure) { dict in
            if let data = dict["data"] as? [[String: Any]] {
                var msgList = Array<MessageModel>()
                for msg in data {
                    let model = MessageModel(JSON: msg)
                    if var model = model {
                        if (msg["content"] as? String) != nil {
                            msgList.append(model)
                        } else if let content = msg["content"] as? [String : Any] {
                            let contentModel = MessageContentModel(JSON: content)
                            let friendRequest = Mapper<FriendRequestModel>().map(JSON: content)
                            model.detailContent = contentModel!.id == 0 ? nil : contentModel
                            model.friendRequest = friendRequest!.id == "" ? nil : friendRequest
                            msgList.append(model)
                        }
                    }
                }
                success(msgList)
                PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
                PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
                PiwikTracker.shared.appName = "bbs.tju.edu.cn/user/me/messages/page/\(page)"
                PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "readMessage", name: "GET", value: nil)
            }
        }
    }

    static func collect(threadID: Int, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        let parameters = ["tid": "\(threadID)"]
        BBSBeacon.request(withType: .post, url: BBSAPI.collect, parameters: parameters, success: success)
    }
    
    static func deleteCollect(threadID: Int, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .delete, url: BBSAPI.deleteCollection(threadID: threadID), parameters: nil, success: success)
    }
    
    static func getCollectionList(failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.collect, parameters: nil, success: success)
    }
    
    static func getMyThreadList(page: Int, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.myThreadList(page: page), parameters: nil, failure: failure, success: success)
    }
    
    static func getMyPostList(page: Int, failure: ((Error)->())? = nil, success: @escaping ([PostModel])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.myPostList(page: page), parameters: nil, failure: failure, success: { dict in
            if let posts = dict["data"] as? [Dictionary<String, Any>] {
               let postModels = Mapper<PostModel>().mapArray(JSONArray: posts)
                success(postModels)
            }
        })
    }
    
    static func loginOld(username: String, password: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        let parameters = ["username": username, "password": password]
        BBSBeacon.request(withType: .post, url: BBSAPI.loginOld, parameters: parameters, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = username
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/old/login"
            PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "OldLogin", name: nil, value: nil)
        })
    }
    
    static func registerOld(username: String, password: String, cid: String, realName: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        let parameters = [
            "username": username,
            "password": password,
            "cid": cid,
            "real_name": realName,
            "token": BBSUser.shared.oldToken!
        ]
        BBSBeacon.request(withType: .post, url: BBSAPI.registerOld, parameters: parameters, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = username
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/old/register"
            PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "OldRegister", name: nil, value: nil)
        })
    }
    

    static func sendMessage(uid: String, content: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        let para = ["to_uid": uid, "content": content]
        BBSBeacon.request(withType: .post, url: BBSAPI.sendMessage, parameters: para, success: { dic in
            
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = "[\(BBSUser.shared.uid ?? 0)] \"\(BBSUser.shared.username ?? "unknown")\""
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/user/\(uid)/"
            PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "message", name: "POST", value: nil)
        })
    }
    
    static func appeal(username: String, cid: String, realName: String, studentNumber: String, email: String, message: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        let parameters = [
            "username": username,
            "cid": cid,
            "real_name": realName,
            "stunum": studentNumber,
            "email": email,
            "message": message
        ]
        BBSBeacon.request(withType: .post, url: BBSAPI.appeal, parameters: parameters, success: { dic in
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = username
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/appeal"
            PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "appeal", name: "POST", value: nil)
        })

    }
    
    static func retrieve(stunum: String?, username: String?, realName: String, cid: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        var parameters = [
            "real_name": realName,
            "cid": cid
        ]
        if stunum != nil {
            parameters["stunum"] = stunum!
        }
        if username != nil {
            parameters["username"] = username!
        }
        BBSBeacon.request(withType: .post, url: BBSAPI.retrieve, parameters: parameters, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = stunum ?? username ?? ""
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/auth"
            PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "Auth", name: nil, value: nil)
        })
    }
    
    static func resetPassword(password: String, failure: ((Error)->())? = nil, success: @escaping ([String: Any])->()) {
        let parameters = [
            "uid": String(BBSUser.shared.uid!),
            "token": BBSUser.shared.resetPasswordToken!,
            "password": password
        ]
        BBSBeacon.request(withType: .post, url: BBSAPI.resetPassword, parameters: parameters, success: { dic in
            success(dic)
            PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
            PiwikTracker.shared.userID = "[\"\(parameters["uid"]!)\"]"
            PiwikTracker.shared.appName = "bbs.tju.edu.cn/sign/reset"
            PiwikTracker.shared.sendEvent(withCategory: "Signing", action: "Reset", name: nil, value: nil)
        })
    }
    
    static func getFriendList(failure: ((Error)->())? = nil, success: @escaping ([UserWrapper])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.friendList, parameters: nil) { dict in
            if let data = dict["data"] as? [[String : Any]] {
                let friends = Mapper<UserWrapper>().mapArray(JSONArray: data)
                success(friends)
            }
        }
    }
    
    static func getDialog(uid: Int, page: Int, failure: ((Error)->())? = nil, success: @escaping ([MessageModel])->()) {
        BBSBeacon.request(withType: .get, url: BBSAPI.dialog(uid: uid, page: page), parameters: nil) { dict in
            if let data = dict["data"] as? [[String : Any]] {
                let messages = Mapper<MessageModel>().mapArray(JSONArray: data)
                success(messages.reversed())
            }
        }
    }
    
    static func getImageAttachmentCode(image: UIImage, progressBlock: ((Progress)->())? = nil, failure: ((Error)->())? = nil, success: @escaping (Int)->()) {
        BBSBeacon.uploadImage(url: BBSAPI.attach, method: .post, image: image, progressBlock: progressBlock, failure: failure, success: { dic in
            if let data = dic["data"] as? [String : String], let code = data["id"] {
                success(Int(code)!)
            }
        })
    }
    
    static func modifyPost(pid: Int, content: String = "", type: String, failure: ((Error)->())? = nil, success: @escaping ()->()) {
        if type == "put" {
            let para = ["content": content]
            BBSBeacon.request(withType: .put, url: BBSAPI.post(pid: pid), parameters: para, success: { _ in
                success()
                PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
                PiwikTracker.shared.userID = "[\(BBSUser.shared.uid!)] \"\(BBSUser.shared.username!)\""
                PiwikTracker.shared.appName = "bbs.tju.edu.cn/iOS_Developer_Do_Not_Know_How_To_Get_it"
                PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "editComment", name: "PUT", value: nil)
            })
        } else if type == "delete" {
            BBSBeacon.request(withType: .delete, url: BBSAPI.post(pid: pid), parameters: nil, success: { _ in
                success()
                PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
                PiwikTracker.shared.userID = "[\(BBSUser.shared.uid!)] \"\(BBSUser.shared.username!)\""
                PiwikTracker.shared.appName = "bbs.tju.edu.cn/iOS_Developer_Do_Not_Know_How_To_Get_it"
                PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "deleteComment", name: "DELETE", value: nil)

            })
        }
    }
    
    static func modifyThread(tid: Int, content: String = "", title: String = "", type: String, failure: ((Error)->())? = nil, success: @escaping ()->()) {
        if type == "put" {
            let para = ["content": content, "title": title]
            BBSBeacon.request(withType: .put, url: BBSAPI.thread(tid: tid), parameters: para, success: { _ in
                success()
                PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
                PiwikTracker.shared.userID = "[\(BBSUser.shared.uid!)] \"\(BBSUser.shared.username!)\""
                PiwikTracker.shared.appName = "bbs.tju.edu.cn/forum/thread/\(tid)/page/1/"
                PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "editThread", name: "PUT", value: nil)
            })
        } else if type == "delete" {
            BBSBeacon.request(withType: .delete, url: BBSAPI.thread(tid: tid), parameters: nil, success: { _ in
                success()
                PiwikTracker.shared.dispatcher.setUserAgent?(DeviceStatus.userAgent)
                PiwikTracker.shared.userID = "[\(BBSUser.shared.uid!)] \"\(BBSUser.shared.username!)\""
                PiwikTracker.shared.appName = "bbs.tju.edu.cn/forum/thread/\(tid)/page/1/"
                PiwikTracker.shared.sendEvent(withCategory: "AjaxSender", action: "deleteThread", name: "DELETE", value: nil)
            })
        }
    }
    
    static func friendRequest(uid: Int, message: String = "", type: String, failure: ((Error)->())? = nil, success: @escaping ([String : Any])->()) {
        if type == "post" {
            let para = ["friend_id": "\(uid)", "message": message]
            BBSBeacon.request(withType: .post, url: BBSAPI.friendList, parameters: para, failure: failure,success: { dic in
                success(dic)
            })
        } else if type == "delete" {
            BBSBeacon.request(withType: .delete, url: BBSAPI.friend(uid: uid), parameters: nil, failure: failure, success: { dic in
                success(dic)
            })
        }
    }
    
    // message id not user id
    static func friendConfirm(messageID: Int, action: String, failure: ((Error)->())? = nil, success: @escaping ([String : Any])->()) {
        var isConfirm = "false"
        if action == "agree" {
            isConfirm = "true"
        } else if action == "reject" {
            isConfirm = "false"
        }
        let para = ["id":"\(messageID)", "confirm":isConfirm]
        BBSBeacon.request(withType: .post, url: BBSAPI.friendConfirm, parameters: para, failure: failure, success: success)
    }
    
    static func friendRemove(uid: Int, failure: ((Error)->())? = nil, success: @escaping ([String : Any])->()) {
        BBSBeacon.request(withType: .delete, url: BBSAPI.friend(uid: uid), parameters: nil, failure: failure, success: success)
    }
}

extension PiwikTracker {
    static var shared: PiwikTracker {
        return PiwikTracker.sharedInstance()
    }
}
