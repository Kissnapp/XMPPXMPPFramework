//
//  XMPPChatMessage.h
//  XMPP_Project
//
//  Created by Peter Lee on 14/9/29.
//  Copyright (c) 2014年 Peter Lee. All rights reserved.
//

#import "XMPPModule.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"
#import "XMPPMessageCoreDataStorage.h"
#import "XMPPMessageCoreDataStorageObject.h"
#import "XMPPExtendMessage.h"
#import "XMPPFramework.h"



/**
 *  When we send a message,we should observer this notice for
 *  distinguishing the message has been send succeed or not
 */
#define SEND_XMPP_EXTEND_CHAT_MESSAGE_SUCCEED @"send_xmpp_extend_chat_message_succeed"   /*When a message has been sent succeed,we will send a this notice to the notification center*/
#define SEND_XMPP_EXTEND_CHAT_MESSAGE_FAILED @"send_xmpp_extend_chat_message_failed"    /*When a message has been sent failed,we will send a this notice to the notification center*/
#define RECEIVE_NEW_XMPP_EXTEND_CHAT_MESSAGE @"receive_new_xmpp_extend_chat_message"

#define RECEIVE_NEW_XMPP_MESSAGE @"receive_new_xmpp_message"



typedef NS_ENUM(NSUInteger, XMPPMessageType){
    XMPPMessageDefaultType = 0,
    XMPPMessageUserRequestType,
    XMPPMessageSystemPushType
};

@protocol XMPPAllMessageStorage;
@protocol XMPPAllMessageDelegate;


@interface XMPPAllMessage : XMPPModule
{
@protected
    
    __strong id <XMPPAllMessageStorage> xmppMessageStorage;
    NSString *activeUser;
    NSString *audioFilePath;
    
@private
    
    BOOL clientSideMessageArchivingOnly;
    BOOL receiveUserRequestMessage;
    BOOL receiveSystemPushMessage;
    BOOL autoArchiveMessage;
    NSXMLElement *preferences;
}


@property (readonly, strong) id <XMPPAllMessageStorage> xmppMessageStorage;

@property (readwrite, assign) BOOL clientSideMessageArchivingOnly;
@property (readwrite, assign) BOOL receiveUserRequestMessage;
@property (readwrite, assign) BOOL receiveSystemPushMessage;
@property (readwrite, assign) BOOL autoArchiveMessage;

@property (nonatomic, strong) NSString *activeUser;
@property (nonatomic, strong) NSString *audioFilePath;

@property (readwrite, copy) NSXMLElement *preferences;

/**
 *  Init with the storage
 *
 *  @param storage The storage
 *
 *  @return The new created object
 */
- (id)initWithMessageStorage:(id <XMPPAllMessageStorage>)storage;
/**
 *  Init with the storage and the queue
 *
 *  @param storage The storage
 *  @param queue   The action queue
 *
 *  @return The Created object
 */
- (id)initWithMessageStorage:(id <XMPPAllMessageStorage>)storage dispatchQueue:(dispatch_queue_t)queue;
/**
 *  ADD the active chat user Who is chatting with
 *
 *  @param userBareJidStr The active user base jid string
 *  @param delegate       The delegate
 *  @param delegateQueue  The dekegate queue
 */
- (void)addActiveUser:(NSString *)userBareJidStr Delegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
/**
 *  remove the active user when we close the chat with the active user
 *
 *  @param delegate The delegate
 */
- (void)removeActiveUserAndDelegate:(id)delegate;
/**
 *  Clear the Given user's chat history
 *
 *  @param userJid user JID
 */
- (void)clearChatHistoryWithUserJid:(XMPPJID *)userJid;


- (void)clearChatHistoryWithBareJidStr:(NSString *)bareJidStr
                       completionBlock:(void (^)(NSString *bareJidStr))completionBlock;

/**
 *  Delete all the messages
 */
- (void)clearAllChatHistorysAndMessages;
/**
 *  read all the unread message,aftering this action,this user will has no unread message
 *
 *  @param userJid user bare jid string
 */
- (void)readAllUnreadMessageWithUserJid:(XMPPJID *)userJid;
/**
 *  read a message with its messageID
 *
 *  @param messageID The given messageID
 */
- (void)readMessageWithMessageId:(NSString *)msgId;
/**
 *  Delete a message object with given message id
 *
 *  @param messageID The given message ID
 */
- (void)deleteMessageWithMessageID:(NSString *)messageID;
/**
 *  Update The message 's sending status
 *
 *  @param messageID The given message id
 */
- (void)updateMessageSendStatusWithMessageID:(NSString *)messageID sendSucceed:(XMPPMessageSendState)sendType;
/**
 *  Set a message's hasBeenRead status into YES;
 *
 *  @param message The given message object
 */
- (void)readMessageWithMessage:(XMPPMessageCoreDataStorageObject *)message;
/**
 *  Delete a message with the message object
 *
 *  @param message The given message object
 */
- (void)deleteMessageWithMessage:(XMPPMessageCoreDataStorageObject *)message;
/**
 *  Update a message with given message object
 *
 *  @param message The given object
 */
- (void)updateMessageSendStatusWithMessage:(XMPPMessageCoreDataStorageObject *)message;
/**
 *  Add a file Path to the XMPPExtendMessageObject in CoreData system
 *
 *  @param filePath The given file path
 *  @param message  The message which we will changed
 */
- (void)addFilePath:(NSString *)filePath toXMPPExtendMessage:(XMPPExtendMessage *)message;
/**
 *  Add a file Path to the XMPPExtendMessageObject in CoreData system
 *
 *  @param filePath  The given file path
 *  @param messageID The ID of a message which we will changed
 */
- (void)addFilePath:(NSString *)filePath toXMPPExtendMessageWithMessageId:(NSString *)messageId;
/**
 *  update a file Path to the XMPPExtendMessageObject in CoreData system
 *
 *  @param filePath The given file path
 *  @param message  The message which we will changed
 */
- (void)updateFilePath:(NSString *)filePath toXMPPExtendMessage:(XMPPExtendMessage *)message;
/**
 *  update a file Path to the XMPPExtendMessageObject in CoreData system
 *
 *  @param filePath  The given file path
 *  @param messageID The ID of a message which we will changed
 */
- (void)updateFilePath:(NSString *)filePath toXMPPExtendMessageObjectWithMessageID:(NSString *)messageID;
/**
 *  Get the last chat message with the given user bare jid string
 *
 *  @param bareJidStr the given user bare jid string
 *
 *  @return The message object
 */
- (XMPPMessageCoreDataStorageObject *)lastMessageWithBareJidStr:(NSString *)bareJidStr;
/**
 *  Fetch a lot of messages with given user bare jid string,the fetch size and the fetch offset
 *
 *  @param bareJidStr  The given user bare jid str
 *  @param fetchSize   The message count we will fetch
 *  @param fetchOffset The beginnig oppsion we want to fetch
 *  @param isPrivate   Whether Fetch the private message
 *
 *  @return A array which contains the fetch result
 */
- (NSArray *)fetchMessagesWithBareJidStr:(NSString *)bareJidStr fetchSize:(NSInteger)fetchSize fetchOffset:(NSInteger)fetchOffset;

/**
 *  Send and Save a message with the given XMPPExtendMessageObject object
 *
 *  @param message The given XMPPExtendMessageObject object
 */
- (void)saveAndSendXMPPExtendMessage:(XMPPExtendMessage *)message;

- (void)saveAndSendXMPPExtendMessage:(XMPPExtendMessage *)message groupType:(XMPPMessageHistoryType)groupType;
/**
 *  Save a XMPPExtendMessageObject object
 *
 *  @param message The given message object
 */
- (void)saveXMPPExtendMessage:(XMPPExtendMessage *)message;

- (void)saveXMPPExtendMessage:(XMPPExtendMessage *)message groupType:(XMPPMessageHistoryType)groupType;
/**
 *  Send a XMPPExtendMessageObject object
 *
 *  @param message The given message obejct
 */
- (void)sendXMPPExtendMessage:(XMPPExtendMessage *)message;
/**
 *  Save the XMPPMessage object
 *  Notice:When we send a message we should call this method first
 *
 *  @param message The message will been sent
 */
- (void)saveXMPPMessage:(XMPPMessage *)message;

- (void)saveXMPPMessage:(XMPPMessage *)message groupType:(XMPPMessageHistoryType)groupType;

- (void)receiveXMPPMessage:(XMPPMessage *)message groupType:(XMPPMessageHistoryType)groupType;

/**
 *  Send a XMPPMessage object
 *
 *  @param message The given message
 */
- (void)sendXMPPMessage:(XMPPMessage *)message;

/**
 *  Save and send a XMPPMessage object
 *
 *  @param message The given message
 */
- (void)saveAndSendXMPPMessage:(XMPPMessage *)message;

- (void)saveAndSendXMPPMessage:(XMPPMessage *)message groupType:(XMPPMessageHistoryType)groupType;

- (void)setAllSendingStateMessagesToFailureState;

- (void)fetchAllSendingStateMessages:(CompletionBlock) completionBlock;

- (void)stopUpdatingMessageHistoryWithBareJidStr:(NSString *)bareJidStr;

- (BOOL)isListHistoryOnTopWithBareJidStr:(NSString *)bareJidStr;

- (void)listHistoryOnTopWithBareJidStr:(NSString *)bareJidStr;

- (void)fetchAllChatHistoryWithCompletionBlock:(CompletionBlock) completionBlock;

@end


//XMPPAllMessageStorage
@protocol XMPPAllMessageStorage <NSObject>

@required

- (BOOL)configureWithParent:(XMPPAllMessage *)aParent queue:(dispatch_queue_t)queue;
- (BOOL)isListHistoryOnTopWithBareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream;
- (void)listHistoryOnTopWithBareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream;
- (void)archiveMessage:(XMPPExtendMessage *)message
                active:(BOOL)active
             groupType:(XMPPMessageHistoryType)groupType
            xmppStream:(XMPPStream *)xmppStream;
- (void)readAllUnreadMessageWithBareUserJid:(NSString *)bareUserJid xmppStream:(XMPPStream *)xmppStream;
- (void)clearChatHistoryWithBareUserJid:(NSString *)bareUserJid
                             xmppStream:(XMPPStream *)xmppStream
                        completionBlock:(void (^)(NSString *bareJidStr))completionBlock;

@optional

- (void)readMessageWithMessageID:(NSString *)messageID xmppStream:(XMPPStream *)xmppStream;
- (void)readMessageWithMessage:(XMPPMessageCoreDataStorageObject *)message xmppStream:(XMPPStream *)xmppStream;

- (void)deleteMessageWithMessageID:(NSString *)messageID xmppStream:(XMPPStream *)xmppStream;
- (void)deleteMessageWithMessage:(XMPPMessageCoreDataStorageObject *)message xmppStream:(XMPPStream *)xmppStream;

- (void)updateMessageWithNewFilePath:(NSString *)newFilePath messageID:(NSString *)messageID xmppStream:(XMPPStream *)xmppStream;
- (void)updateMessageSendStatusWithMessageID:(NSString *)messageID sendSucceed:(XMPPMessageSendState)sendType xmppStream:(XMPPStream *)xmppStream;
- (void)updateMessageSendStatusWithMessage:(XMPPMessageCoreDataStorageObject *)message success:(BOOL)success xmppStream:(XMPPStream *)xmppStream;
- (id)lastMessageWithBareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)xmppStream;
- (NSArray *)fetchMessagesWithBareJidStr:(NSString *)bareJidStr fetchSize:(NSInteger)fetchSize fetchOffset:(NSInteger)fetchOffset xmppStream:(XMPPStream *)xmppStream;
- (void)clearAllChatHistoryAndMessageWithXMPPStream:(XMPPStream *)xmppStream;

- (void)setAllSendingStateMessagesToFailureStateWithXMPPStream:(XMPPStream *)stream;
- (id)allSendingStateMessagesWithXMPPStream:(XMPPStream *)stream;
- (id)allHistoryMessageWithXMPPStream:(XMPPStream *)xmppStream;

- (void)stopUpdatingMessageHistoryWithBareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream;

@end


//XMPPAllMessageDelegate
@protocol XMPPAllMessageDelegate <NSObject>

@required

@optional

- (void)xmppAllMessage:(XMPPAllMessage *)xmppAllMessage didReceiveXMPPMessage:(XMPPMessage *)message;
- (void)xmppAllMessage:(XMPPAllMessage *)xmppAllMessage willSendXMPPMessage:(XMPPMessage *)message;
- (void)xmppAllMessage:(XMPPAllMessage *)xmppAllMessage didReceiveXMPPExtendMessage:(XMPPExtendMessage *)message;

@end

