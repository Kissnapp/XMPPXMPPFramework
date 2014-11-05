//
//  XMPPChatRoomUserCoreDataStorageObject.m
//  XMPP_Project
//
//  Created by Peter Lee on 14/11/4.
//  Copyright (c) 2014年 Peter Lee. All rights reserved.
//

#import "XMPPChatRoomUserCoreDataStorageObject.h"


@implementation XMPPChatRoomUserCoreDataStorageObject

@dynamic bareJidStr;
@dynamic chatRoomBareJidStr;
@dynamic nickeName;
@dynamic streamBareJidStr;

#pragma mark -
#pragma mark - Setters/Getters Methods

- (NSString *)bareJidStr
{
    [self willAccessValueForKey:@"bareJidStr"];
    NSString *value = [self primitiveValueForKey:@"bareJidStr"];
    [self didAccessValueForKey:@"bareJidStr"];
    return value;
}
            
- (void)setBareJidStr:(NSString *)value
{
    [self willChangeValueForKey:@"bareJidStr"];
    [self setPrimitiveValue:value forKey:@"bareJidStr"];
    [self didChangeValueForKey:@"bareJidStr"];
}

- (NSString *)chatRoomBareJidStr
{
    [self willAccessValueForKey:@"chatRoomBareJidStr"];
    NSString *value = [self primitiveValueForKey:@"chatRoomBareJidStr"];
    [self didAccessValueForKey:@"chatRoomBareJidStr"];
    return value;
}

- (void)setChatRoomBareJidStr:(NSString *)value
{
    [self willChangeValueForKey:@"chatRoomBareJidStr"];
    [self setPrimitiveValue:value forKey:@"chatRoomBareJidStr"];
    [self didChangeValueForKey:@"chatRoomBareJidStr"];
}

- (NSString *)nickeName
{
    [self willAccessValueForKey:@"nickeName"];
    NSString *value = [self primitiveValueForKey:@"nickeName"];
    [self didAccessValueForKey:@"nickeName"];
    return value;
}

- (void)setNickeName:(NSString *)value
{
    [self willChangeValueForKey:@"nickeName"];
    [self setPrimitiveValue:value forKey:@"nickeName"];
    [self didChangeValueForKey:@"nickeName"];
}

- (NSString *)streamBareJidStr
{
    [self willAccessValueForKey:@"streamBareJidStr"];
    NSString *value = [self primitiveValueForKey:@"streamBareJidStr"];
    [self didAccessValueForKey:@"streamBareJidStr"];
    return value;
}

- (void)setStreamBareJidStr:(NSString *)value
{
    [self willChangeValueForKey:@"streamBareJidStr"];
    [self setPrimitiveValue:value forKey:@"streamBareJidStr"];
    [self didChangeValueForKey:@"streamBareJidStr"];
}

#pragma mark -
#pragma mark - Public Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Creation & Updates
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)insertInManagedObjectContext:(NSManagedObjectContext *)moc
                            withID:(NSString *)id
                            chatRoomJid:(NSString*)roomJid
                            streamBareJidStr:(NSString *)streamBareJidStr
{
    if (id == nil){
        NSLog(@"XMPPChatRoomCoreDataStorageObject: invalid jid (nil)");
        return nil;
    }
    
    XMPPChatRoomUserCoreDataStorageObject *chatRoomuser;
    chatRoomuser = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPChatRoomUserCoreDataStorageObject"
                                             inManagedObjectContext:moc];
    
    chatRoomuser.streamBareJidStr = streamBareJidStr;
    chatRoomuser.bareJidStr = id;
    chatRoomuser.chatRoomBareJidStr = roomJid;
    chatRoomuser.nickeName = nil;
    
   
    return chatRoomuser;
}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext *)moc
                  withNSDictionary:(NSDictionary *)Dic
                       chatRoomJid:(NSString*)roomJid
                  streamBareJidStr:(NSString *)streamBareJidStr
{
    
    NSString *jid = [Dic objectForKey:@"jid"];
    
    if (jid == nil){
        NSLog(@"XMPPChatRoomUserCoreDataStorageObject: invalid Dic (missing or invalid jid): %@", Dic.description);
        return nil;
    }
    
    XMPPChatRoomUserCoreDataStorageObject *chatRoomUser;
    chatRoomUser = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPChatRoomUserCoreDataStorageObject"
                                             inManagedObjectContext:moc];
    
    
    chatRoomUser.streamBareJidStr = streamBareJidStr;
    chatRoomUser.chatRoomBareJidStr = roomJid;
    [chatRoomUser updateWithDictionary:Dic];
    
    return chatRoomUser;
  
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Delete method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)deleteInManagedObjectContext:(NSManagedObjectContext *)moc
                    withNSDictionary:(NSDictionary *)Dic chatRoomJid:(NSString*)roomJid
                    streamBareJidStr:(NSString *)streamBareJidStr;
{
    NSString *jid = [Dic objectForKey:@"jid"];
    return [self deleteInManagedObjectContext:moc
                                       withID:jid chatRoomJid:roomJid
                             streamBareJidStr:streamBareJidStr];
    
    
}
+ (BOOL)deleteInManagedObjectContext:(NSManagedObjectContext *)moc
                              withID:(NSString *)id
                                chatRoomJid:(NSString*)roomJid
                                streamBareJidStr:(NSString *)streamBareJidStr
{
    if (id == nil) return NO;
    if (moc == nil) return NO;
    
    XMPPChatRoomUserCoreDataStorageObject *deleteObject = [XMPPChatRoomUserCoreDataStorageObject objectInManagedObjectContext:moc withBareJidStr:id chatRoomJid:roomJid streamBareJidStr:streamBareJidStr];
    if (deleteObject){
        
        [moc deleteObject:deleteObject];
        return YES;
    }
    
    return NO;
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark  Update methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)updateInManagedObjectContext:(NSManagedObjectContext *)moc
                    withNSDictionary:(NSDictionary *)Dic
                         chatRoomJid:(NSString*)roomJid
                    streamBareJidStr:(NSString *)streamBareJidStr
{
    NSString *id = [Dic objectForKey:@"bareJidStr"];
    
    if (id == nil) return NO;
    if (moc == nil) return NO;
    
    NSError *error = nil;
    
    XMPPChatRoomUserCoreDataStorageObject *updateObject = [XMPPChatRoomUserCoreDataStorageObject objectInManagedObjectContext:moc withBareJidStr:id chatRoomJid:roomJid streamBareJidStr:streamBareJidStr];
    //if we find the object we will update for,we update it with the new obejct
    if (updateObject){
        
        [updateObject updateWithDictionary:Dic];
        return YES;
    }
    return NO;
}
+ (BOOL)updateOrInsertObjectInManagedObjectContext:(NSManagedObjectContext *)moc
                                  withNSDictionary:(NSDictionary *)Dic
                                  chatRoomJid:(NSString*)roomJid
                                  streamBareJidStr:(NSString *)streamBareJidStr
{
    NSString *id = [Dic objectForKey:@"jid"];
    if (id == nil) return NO;
    if (moc == nil) return NO;
    XMPPChatRoomUserCoreDataStorageObject* updateOrInsertObject = [XMPPChatRoomUserCoreDataStorageObject objectInManagedObjectContext:moc withBareJidStr:id chatRoomJid:roomJid  streamBareJidStr:streamBareJidStr];
    //if the object we find alreadly in the coredata system ,we should update it
    if (updateOrInsertObject){
        
        [updateOrInsertObject updateWithDictionary:Dic];
        
        return YES;
        
    }else{//if not find the object in the CoreData system ,we should insert the new object to it
        //FIXME:There is a bug maybe here
        updateOrInsertObject   = [XMPPChatRoomUserCoreDataStorageObject insertInManagedObjectContext:moc
                                                                      withNSDictionary:Dic
                                                                      chatRoomJid: roomJid
                                                                      streamBareJidStr:streamBareJidStr];
       // [moc insertObject:updateOrInsertObject];
         return YES;
    }
    return NO;
    

}
+ (id)fetchObjectInManagedObjectContext:(NSManagedObjectContext *)moc
                         withBareJidStr:(NSString *)bareJidStr
                         chatRoomJid:(NSString*)roomJid
                         streamBareJidStr:(NSString *)streamBareJidStr
{
    return [XMPPChatRoomUserCoreDataStorageObject objectInManagedObjectContext:moc
                                                                withBareJidStr:bareJidStr
                                                                chatRoomJid:roomJid
                                                              streamBareJidStr:streamBareJidStr];
}

+ (XMPPChatRoomUserCoreDataStorageObject *)objectInManagedObjectContext:(NSManagedObjectContext *)moc
                                                         withBareJidStr:(NSString *)bareJidStr
                                                            chatRoomJid:(NSString*)roomJid
                                                       streamBareJidStr:(NSString *)streamBareJidStr
{
    if (bareJidStr == nil) return nil;
    if (moc == nil) return nil;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPChatRoomUserCoreDataStorageObject"
                                              inManagedObjectContext:moc];
    
    NSPredicate *predicate;
    if (streamBareJidStr == nil)
        predicate = [NSPredicate predicateWithFormat:@"jid == %@ AND chatRoomBareJidStr == %@", bareJidStr,roomJid];
    else
        predicate = [NSPredicate predicateWithFormat:@"jid == %@ AND chatRoomBareJidStr == %@ AND streamBareJidStr == %@",
                     bareJidStr,roomJid, streamBareJidStr];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setIncludesPendingChanges:YES];
    [fetchRequest setFetchLimit:1];
    
    NSArray *results = [moc executeFetchRequest:fetchRequest error:nil];
    
    return (XMPPChatRoomUserCoreDataStorageObject *)[results lastObject];
}


#pragma mark -
#pragma mark - Private Methods
- (void)updateWithDictionary:(NSDictionary *)Dic
{
    NSString *bareJidStr = [Dic objectForKey:@"bareJidStr"];
    NSString *roomBareJidStr = [Dic objectForKey:@"RoomBareJidStr"];
    NSString *nickNameStr = [Dic objectForKey:@"nicknameStr"];
    NSString *streamBareJidStr = [Dic objectForKey:@"streamBareJidStr"];
    if (bareJidStr == nil){
        NSLog(@"XMPPChatRoomUserCoreDataStorageObject: invalid Dic (missing or invalid jid): %@", Dic.description);
        return;
    }
    if (self.bareJidStr) {
        self.bareJidStr = bareJidStr;
    }
    if (self.chatRoomBareJidStr) {
        self.chatRoomBareJidStr = roomBareJidStr;
    }
    if (self.nickeName) {
        self.nickeName = nickNameStr;
    }
    if (self.streamBareJidStr) {
        self.streamBareJidStr = streamBareJidStr;
    }
  

}

@end
