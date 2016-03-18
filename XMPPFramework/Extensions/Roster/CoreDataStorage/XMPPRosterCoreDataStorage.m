#import "XMPPRosterCoreDataStorage.h"
#import "XMPPGroupCoreDataStorageObject.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPResourceCoreDataStorageObject.h"
#import "XMPPRosterPrivate.h"
#import "XMPPCoreDataStorageProtected.h"
#import "XMPPRosterVersionCoreDataStorageObject.h"
#import "XMPP.h"
#import "XMPPLogging.h"
#import "NSNumber+XMPP.h"
#import "NSString+ChineseToPinYin.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
#if DEBUG
  static const int xmppLogLevel = XMPP_LOG_LEVEL_INFO; // | XMPP_LOG_FLAG_TRACE;
#else
  static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

#define AssertPrivateQueue() \
        NSAssert(dispatch_get_specific(storageQueueTag), @"Private method: MUST run on storageQueue");


@implementation XMPPRosterCoreDataStorage

static XMPPRosterCoreDataStorage *sharedInstance;

+ (instancetype)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sharedInstance = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:nil storeOptions:nil];
	});
	
	return sharedInstance;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Setup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)commonInit
{
	XMPPLogTrace();
	[super commonInit];
	
	// This method is invoked by all public init methods of the superclass
    autoRemovePreviousDatabaseFile = YES;
	autoRecreateDatabaseFile = YES;
    
	rosterPopulationSet = [[NSMutableSet alloc] init];
}

- (BOOL)configureWithParent:(XMPPRoster *)aParent queue:(dispatch_queue_t)queue
{
	NSParameterAssert(aParent != nil);
	NSParameterAssert(queue != NULL);
	
	@synchronized(self)
	{
		if ((parent == nil) && (parentQueue == NULL))
		{
			parent = aParent;
			parentQueue = queue;
			parentQueueTag = &parentQueueTag;
			dispatch_queue_set_specific(parentQueue, parentQueueTag, parentQueueTag, NULL);
			
#if !OS_OBJECT_USE_OBJC
			dispatch_retain(parentQueue);
#endif
			
			return YES;
		}
	}
    
    return NO;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
	if (parentQueue)
		dispatch_release(parentQueue);
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_clearAllResourcesForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	AssertPrivateQueue();
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPResourceCoreDataStorageObject"
	                                          inManagedObjectContext:moc];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	[fetchRequest setFetchBatchSize:saveThreshold];
	
	if (stream)
	{
		NSPredicate *predicate;
		predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@",
		                                    [[self myJIDForXMPPStream:stream] bare]];
		
		[fetchRequest setPredicate:predicate];
	}
	
	NSArray *allResources = [moc executeFetchRequest:fetchRequest error:nil];
	
	NSUInteger unsavedCount = [self numberOfUnsavedChanges];
	
	for (XMPPResourceCoreDataStorageObject *resource in allResources)
	{
        XMPPUserCoreDataStorageObject *user = resource.user;
		[moc deleteObject:resource];
        [user recalculatePrimaryResource];
        
		if (++unsavedCount >= saveThreshold)
		{
			[self save];
			unsavedCount = 0;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didCreateManagedObjectContext
{
	// This method is overriden from the XMPPCoreDataStore superclass.
	// From the documentation:
	// 
	// Override me, if needed, to provide customized behavior.
	// 
	// For example, you may want to perform cleanup of any non-persistent data before you start using the database.
	// 
	// The default implementation does nothing.
	
	
	// Reserved for future use (directory versioning).
	// Perhaps invoke [self _clearAllResourcesForXMPPStream:nil] ?
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPUserCoreDataStorageObject *)myUserForXMPPStream:(XMPPStream *)stream
                                  managedObjectContext:(NSManagedObjectContext *)moc
{
	// This is a public method, so it may be invoked on any thread/queue.
	
	XMPPLogTrace();
	
	XMPPJID *myJID = stream.myJID;
	if (myJID == nil)
	{
		return nil;
	}
	
	return [self userForJID:myJID xmppStream:stream managedObjectContext:moc];
}

- (XMPPResourceCoreDataStorageObject *)myResourceForXMPPStream:(XMPPStream *)stream
                                          managedObjectContext:(NSManagedObjectContext *)moc
{
	// This is a public method, so it may be invoked on any thread/queue.
	
	XMPPLogTrace();
	
	XMPPJID *myJID = stream.myJID;
	if (myJID == nil)
	{
		return nil;
	}
	
	return [self resourceForJID:myJID xmppStream:stream managedObjectContext:moc];
}

- (XMPPUserCoreDataStorageObject *)userForJID:(XMPPJID *)jid
                                   xmppStream:(XMPPStream *)stream
                         managedObjectContext:(NSManagedObjectContext *)moc
{
	// This is a public method, so it may be invoked on any thread/queue.
	
	XMPPLogTrace();
	
	if (jid == nil) return nil;
	if (moc == nil) return nil;
	
	NSString *bareJIDStr = [jid bare];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
	                                          inManagedObjectContext:moc];
	
	NSPredicate *predicate;
	if (stream == nil)
		predicate = [NSPredicate predicateWithFormat:@"jidStr == %@", bareJIDStr];
	else
		predicate = [NSPredicate predicateWithFormat:@"jidStr == %@ AND streamBareJidStr == %@",
					 bareJIDStr, [[self myJIDForXMPPStream:stream] bare]];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setIncludesPendingChanges:YES];
	[fetchRequest setFetchLimit:1];
	
	NSArray *results = [moc executeFetchRequest:fetchRequest error:nil];
	
	return (XMPPUserCoreDataStorageObject *)[results lastObject];
}

- (XMPPResourceCoreDataStorageObject *)resourceForJID:(XMPPJID *)jid
										   xmppStream:(XMPPStream *)stream
                                 managedObjectContext:(NSManagedObjectContext *)moc
{
	// This is a public method, so it may be invoked on any thread/queue.
	
	XMPPLogTrace();
	
	if (jid == nil) return nil;
	if (moc == nil) return nil;
	
	NSString *fullJIDStr = [jid full];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPResourceCoreDataStorageObject"
	                                          inManagedObjectContext:moc];
	
	NSPredicate *predicate;
	if (stream == nil)
		predicate = [NSPredicate predicateWithFormat:@"jidStr == %@", fullJIDStr];
	else
		predicate = [NSPredicate predicateWithFormat:@"jidStr == %@ AND streamBareJidStr == %@",
					 fullJIDStr, [[self myJIDForXMPPStream:stream] bare]];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setIncludesPendingChanges:YES];
	[fetchRequest setFetchLimit:1];
	
	NSArray *results = [moc executeFetchRequest:fetchRequest error:nil];
	
	return (XMPPResourceCoreDataStorageObject *)[results lastObject];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Protocol Private API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		[rosterPopulationSet addObject:[NSNumber xmpp_numberWithPtr:(__bridge void *)stream]];
    
		// Clear anything already in the roster core data store.
		// 
		// Note: Deleting a user will delete all associated resources
		// because of the cascade rule in our core data model.
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setFetchBatchSize:saveThreshold];
		
		if (stream)
		{
			NSPredicate *predicate;
			predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ && isPhoneUser == %@",
			                                     [[self myJIDForXMPPStream:stream] bare], @(NO)];
			
			[fetchRequest setPredicate:predicate];
		}
		
		NSArray *allUsers = [moc executeFetchRequest:fetchRequest error:nil];
		
		for (XMPPUserCoreDataStorageObject *user in allUsers)
		{
			[moc deleteObject:user];
		}
		
		[XMPPGroupCoreDataStorageObject clearEmptyGroupsInManagedObjectContext:moc];
	}];
}

- (void)endRosterPopulationForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		[rosterPopulationSet removeObject:[NSNumber xmpp_numberWithPtr:(__bridge void *)stream]];
	}];
}

- (void)handleRosterItem:(NSXMLElement *)itemSubElement xmppStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	//NSLog(@"NSXMLElement:%@",itemSubElement.description);
	// Remember XML heirarchy memory management rules.
	// The passed parameter is a subnode of the IQ, and we need to pass it to an asynchronous operation.
	NSXMLElement *item = [itemSubElement copy];
	
	[self scheduleBlock:^{
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		
		if ([rosterPopulationSet containsObject:[NSNumber xmpp_numberWithPtr:(__bridge void *)stream]])
		{
			NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
            
            NSString *subscription = [item attributeStringValueForName:@"subscription"];
            
            // we should delete the local user info which come from cell phone contact list
            if ([subscription isEqualToString:@"both"]) {
                
                NSString *jidStr = [item attributeStringValueForName:@"jid"];
                XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
                
                XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
                
                if (user) {
                    [moc deleteObject:user];
                }
            }
			
			[XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
			                                                   withItem:item
			                                           streamBareJidStr:streamBareJidStr];
		}
		else
		{
			NSString *jidStr = [item attributeStringValueForName:@"jid"];
			XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
			
			XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
			
			NSString *subscription = [item attributeStringValueForName:@"subscription"];
            // MARK: - I have changed this value here,orgin value is @"remove",but our server will send us @"none" instead of the @"remove"
			//if ([subscription isEqualToString:@"remove"])
            if ([subscription isEqualToString:@"none"] || [subscription isEqualToString:@"remove"])
			{
				if (user)
				{
					[moc deleteObject:user];
				}
			}
			else
			{
				if (user)
				{
					[user updateWithItem:item];
				}
				else
				{
                    NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
                    
                    // MARK: when inserting a roster,wo should find that whether this item has a local data,if this is one,delete it
                    
                    if ([subscription isEqualToString:@"both"]) {
                        
                        XMPPUserCoreDataStorageObject *localUser = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
                        
                        if (localUser) {
                            [moc deleteObject:localUser];
                        }
                    }
                    
					[XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
					                                                   withItem:item
					                                           streamBareJidStr:streamBareJidStr];
				}
			}
		}
	}];
}

- (void)addLocalUser:(NSDictionary *)userInfoDic xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    //NSLog(@"NSXMLElement:%@",itemSubElement.description);
    // Remember XML heirarchy memory management rules.
    // The passed parameter is a subnode of the IQ, and we need to pass it to an asynchronous operation.
    
    [self scheduleBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
        
        NSString *phone = userInfoDic[@"phone"];
        UIImage *photo = userInfoDic[@"photo"];
        NSString *nickname = userInfoDic[@"name"];
        
        if (phone) {
            
            NSString *phoneJidStr = [phone stringByAppendingString:[NSString stringWithFormat:@"@%@",[[self myJIDForXMPPStream:stream] domain]]];
        
            XMPPUserCoreDataStorageObject *user = [XMPPUserCoreDataStorageObject objectInManagedObjectContext:moc
                                                                                               withBareJidStr:phoneJidStr
                                                                                             streamBareJidStr:streamBareJidStr];
            if (user) {// 跟新
                if (photo) user.photo = photo;
                if (nickname) user.nickname = nickname;
                user.phoneNumber = phone;
            }else{
                user = [XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
                                                                           withJID:[XMPPJID jidWithString:phoneJidStr]
                                                                  streamBareJidStr:streamBareJidStr];
                user.isPhoneUser = @(YES);
                if (photo) user.photo = photo;
                if (nickname) {
                    user.nickname = nickname;
                    user.englishName = [nickname chineseToPinYin];
                    user.sectionName = [user.englishName firstLetter];
                }
                user.phoneNumber = phone;
            }
        }
    }];

}

- (void)replaceLocalUserJidStrWithPhone:(NSString *)phone newBareJidStr:(NSString *)newBareJidStr xmppStream:(XMPPStream *)stream
{
    [self scheduleBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
        
        NSString *phoneJidStr = [phone stringByAppendingString:[NSString stringWithFormat:@"@%@",[[self myJIDForXMPPStream:stream] domain]]];
        
        
        XMPPUserCoreDataStorageObject *user = [XMPPUserCoreDataStorageObject objectInManagedObjectContext:moc
                                                                                           withBareJidStr:phoneJidStr
                                                                                         streamBareJidStr:streamBareJidStr];
        if (user) {// 跟新
            user.jidStr = newBareJidStr;
        }
    }];
}

- (void)handlePresence:(XMPPPresence *)presence xmppStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		XMPPJID *jid = [presence from];
		NSManagedObjectContext *moc = [self managedObjectContext];
		
		NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
		
		XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
		
		if (user == nil && [parent allowRosterlessOperation])
		{
			// This may happen if the roster is in rosterlessOperation mode.
			
			user = [XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
			                                                           withJID:[presence from]
			                                                  streamBareJidStr:streamBareJidStr];
		}
		
		[user updateWithPresence:presence streamBareJidStr:streamBareJidStr];
	}];
}

- (BOOL)userExistsWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	__block BOOL result = NO;
	
	[self executeBlock:^{
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
		
		result = (user != nil);
	}];
	
	return result;
}

- (BOOL)hasRequestSubscribeSomeoneEarlierWithBareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    __block BOOL result = NO;
    
    [self executeBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        XMPPUserCoreDataStorageObject *user = [self userForJID:[XMPPJID jidWithString:bareJidStr]
                                                    xmppStream:stream
                                          managedObjectContext:moc];
        
        result = ([user.subscription isEqualToString:@"to"]);
    }];
    
    return result;
}

#if TARGET_OS_IPHONE
- (void)setPhoto:(UIImage *)photo forUserWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
#else
- (void)setPhoto:(NSImage *)photo forUserWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
#endif
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
		
		if (user){
			user.photo = photo;
		}
	}];
}

- (void)clearAllResourcesForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		[self _clearAllResourcesForXMPPStream:stream];
	}];
}

- (void)clearAllUsersAndResourcesForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		// Note: Deleting a user will delete all associated resources
		// because of the cascade rule in our core data model.
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
												  inManagedObjectContext:moc];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setFetchBatchSize:saveThreshold];
		
		if (stream)
		{
			NSPredicate *predicate;
            predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ && isPhoneUser == %@",
                         [[self myJIDForXMPPStream:stream] bare], @(NO)];
			
			[fetchRequest setPredicate:predicate];
		}
		
		NSArray *allUsers = [moc executeFetchRequest:fetchRequest error:nil];
		
		NSUInteger unsavedCount = [self numberOfUnsavedChanges];
		
		for (XMPPUserCoreDataStorageObject *user in allUsers)
		{
			[moc deleteObject:user];
			
			if (++unsavedCount >= saveThreshold)
			{
				[self save];
				unsavedCount = 0;
			}
		}
    
		[XMPPGroupCoreDataStorageObject clearEmptyGroupsInManagedObjectContext:moc];
	}];
}

- (NSArray *)jidsForXMPPStream:(XMPPStream *)stream{
    
    XMPPLogTrace();
    
    __block NSMutableArray *results = [NSMutableArray array];
	
	[self executeBlock:^{
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
												  inManagedObjectContext:moc];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setFetchBatchSize:saveThreshold];
		
		if (stream)
		{
			NSPredicate *predicate;
			predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@",
                         [[self myJIDForXMPPStream:stream] bare]];
			
			[fetchRequest setPredicate:predicate];
		}
		
		NSArray *allUsers = [moc executeFetchRequest:fetchRequest error:nil];
        
        for(XMPPUserCoreDataStorageObject *user in allUsers){
            [results addObject:[user.jid bareJID]];
        }
		
	}];
    
    return results;
}

- (void)getSubscription:(NSString **)subscription
                    ask:(NSString **)ask
               nickname:(NSString **)nickname
                 groups:(NSArray **)groups
                 forJID:(XMPPJID *)jid
             xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self executeBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
        
        if(user)
        {
            if(subscription)
            {
                *subscription = user.subscription;
            }
            
            if(ask)
            {
                *ask = user.ask;
            }
            
            if(nickname)
            {
                *nickname = user.nickname;
            }
            
            if(groups)
            {
                if([user.groups count])
                {
                    NSMutableArray *groupNames = [NSMutableArray array];
                    
                    for(XMPPGroupCoreDataStorageObject *group in user.groups){
                        [groupNames addObject:group.name];
                    }
                    
                    *groups = groupNames;
                }
            }
        }
    }];
}

- (NSString *)versionWithXMPPStream:(XMPPStream *)stream
{
    __block NSString *version = nil;
    
    [self executeBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([XMPPRosterVersionCoreDataStorageObject class])
                                                  inManagedObjectContext:moc];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:1];
        
        if (stream)
        {
            NSPredicate *predicate;
            predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@",
                         [[self myJIDForXMPPStream:stream] bare]];
            
            [fetchRequest setPredicate:predicate];
        }
        
        XMPPRosterVersionCoreDataStorageObject *rosterVersion = [[moc executeFetchRequest:fetchRequest error:nil] lastObject];
        version = rosterVersion.version;
    }];
    
    return version;
}

- (void)insertOrUpdateRosterVersion:(NSString *)rosterVersion xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self scheduleBlock:^{
        
        // Note: Deleting a user will delete all associated resources
        // because of the cascade rule in our core data model.
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        [XMPPRosterVersionCoreDataStorageObject updateOrInsertInManagedObjectContext:moc
                                                                             version:rosterVersion
                                                                    streamBareJidStr:[[self myJIDForXMPPStream:stream] bare]];
    }];
}


- (void)saveSubscribeWithBareJidStr:(NSString *)bareJidStr
                           nickName:(NSString *)nickName
                            message:(NSString *)message
                         xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self scheduleBlock:^{
        
        // Note: Deleting a user will delete all associated resources
        // because of the cascade rule in our core data model.
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr =[[self myJIDForXMPPStream:stream] bare];
        
        XMPPSubscribeCoreDataStorageObject *subscribe = [XMPPSubscribeCoreDataStorageObject objectInManagedObjectContext:moc
                                                                                                              bareJidStr:bareJidStr
                                                                                                        streamBareJidStr:streamBareJidStr];
        if (subscribe) {
            
            if (nickName.length > 0) subscribe.nickName = nickName;
            if (message.length > 0) subscribe.message = message;
            subscribe.time = [NSDate date];
            
        }else{
            subscribe = [XMPPSubscribeCoreDataStorageObject insertInManagedObjectContext:moc
                                                                              bareJidStr:bareJidStr
                                                                                nickName:nickName
                                                                                 message:message
                                                                        streamBareJidStr:streamBareJidStr];
        }
    }];
}

- (void)accpetSubscribeWithBareJidStr:(NSString *)bareJidStr
                           xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self scheduleBlock:^{
        
        // Note: Deleting a user will delete all associated resources
        // because of the cascade rule in our core data model.
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr =[[self myJIDForXMPPStream:stream] bare];
        
        XMPPSubscribeCoreDataStorageObject *subscribe = [XMPPSubscribeCoreDataStorageObject objectInManagedObjectContext:moc
                                                                                                              bareJidStr:bareJidStr
                                                                                                        streamBareJidStr:streamBareJidStr];
        if (subscribe) {
            
            subscribe.state = @(XMPPSubscribeStateAccept);
            
        }
    }];
}

- (void)refuseSubscribeWithBareJidStr:(NSString *)bareJidStr
                           xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self scheduleBlock:^{
        
        // Note: Deleting a user will delete all associated resources
        // because of the cascade rule in our core data model.
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr =[[self myJIDForXMPPStream:stream] bare];
        
        XMPPSubscribeCoreDataStorageObject *subscribe = [XMPPSubscribeCoreDataStorageObject objectInManagedObjectContext:moc
                                                                                                              bareJidStr:bareJidStr
                                                                                                        streamBareJidStr:streamBareJidStr];
        if (subscribe) {
            
            subscribe.state = @(XMPPSubscribeStateRefuse);
            
        }
    }];
}

- (void)ignoreAllSubscriptionRequestsWithXMPPStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self scheduleBlock:^{
        
        // Note: Deleting a user will delete all associated resources
        // because of the cascade rule in our core data model.
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr =[[self myJIDForXMPPStream:stream] bare];
        
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([XMPPSubscribeCoreDataStorageObject class])
                                                  inManagedObjectContext:moc];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:saveThreshold];
        
        if (stream){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ AND state == %@", streamBareJidStr, @(XMPPSubscribeStateReceive)];
            
            [fetchRequest setPredicate:predicate];
        }
        
        NSArray *subscribes = [moc executeFetchRequest:fetchRequest error:nil];
        
        [subscribes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            XMPPSubscribeCoreDataStorageObject *subscribe = obj;
            
            subscribe.state = @(XMPPSubscribeStateIgnore);
        }];
        

    }];
}

- (void)deleteSubscribeRequestWithBareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    [self scheduleBlock:^{
        
        // Note: Deleting a user will delete all associated resources
        // because of the cascade rule in our core data model.
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSString *streamBareJidStr =[[self myJIDForXMPPStream:stream] bare];
        
        [XMPPSubscribeCoreDataStorageObject deleteInManagedObjectContext:moc
                                                              bareJidStr:bareJidStr
                                                        streamBareJidStr:streamBareJidStr];
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPRosterQueryModuleStorage
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)userExistInRosterForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    __block BOOL result = NO;
    
    [self executeBlock:^{
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                                  inManagedObjectContext:moc];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchLimit:1];
        
        if (stream)
        {
            NSPredicate *predicate;
            predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@ && %K == %@",@"jidStr",[jid bare],@"streamBareJidStr",
                         [[self myJIDForXMPPStream:stream] bare], @"subscription", @"both"];
            
            [fetchRequest setPredicate:predicate];
        }
        
        XMPPUserCoreDataStorageObject *user = [[moc executeFetchRequest:fetchRequest error:nil] lastObject];
        
        if (user) result = YES;
        
    }];
    
    return result;
}

- (BOOL)phoneUserExistInRosterForPhone:(NSString *)phone xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    __block BOOL result = NO;
    
    [self executeBlock:^{
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([XMPPUserCoreDataStorageObject class])
                                                  inManagedObjectContext:moc];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchLimit:1];
        
        if (stream)
        {
            NSPredicate *predicate;
            predicate = [NSPredicate predicateWithFormat:@"(jidStr == %@ || phoneNumber == %@ ) && streamBareJidStr == %@",phone, phone,
                         [[self myJIDForXMPPStream:stream] bare]];
            
            [fetchRequest setPredicate:predicate];
        }
        
        XMPPUserCoreDataStorageObject *user = [[moc executeFetchRequest:fetchRequest error:nil] lastObject];
        
        if (user) result = YES;
        
    }];
    
    return result;
}

- (NSString *)nickNameForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    __block NSString *result = nil;
    
    [self executeBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                                  inManagedObjectContext:moc];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchLimit:1];
        
        if (stream)
        {
            NSPredicate *predicate;
            predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@",@"jidStr",[jid bare],@"streamBareJidStr",
                         [[self myJIDForXMPPStream:stream] bare]];
            
            [fetchRequest setPredicate:predicate];
        }
        
        XMPPUserCoreDataStorageObject *user = [[moc executeFetchRequest:fetchRequest error:nil] lastObject];
        
        if (user) result = user.nickname;
    }];
    
    return result;
}
- (NSString *)displayNameForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    XMPPLogTrace();
    
    __block NSString *result = nil;
    
    [self executeBlock:^{
        
        NSManagedObjectContext *moc = [self managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                                  inManagedObjectContext:moc];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchLimit:1];
        
        if (stream)
        {
            NSPredicate *predicate;
            predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@",@"jidStr",[jid bare],@"streamBareJidStr",
                         [[self myJIDForXMPPStream:stream] bare]];
            
            [fetchRequest setPredicate:predicate];
        }
        
        XMPPUserCoreDataStorageObject *user = [[moc executeFetchRequest:fetchRequest error:nil] lastObject];
        
        if (user) result = user.displayName;
    }];
    
    return result;
}


- (BOOL)privateModelForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    return YES;
}
- (void)clearRosterForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
 
}

@end
