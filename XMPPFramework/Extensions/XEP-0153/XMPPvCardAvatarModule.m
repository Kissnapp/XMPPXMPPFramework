//
//  XMPPvCardAvatarModule.h
//  XEP-0153 vCard-Based Avatars
//
//  Created by Eric Chamberlain on 3/9/11.
//  Copyright 2011 RF.com. All rights reserved.

#import "XMPPvCardAvatarModule.h"

#import "NSData+XMPP.h"
#import "NSXMLElement+XMPP.h"
#import "XMPPLogging.h"
#import "XMPPPresence.h"
#import "XMPPStream.h"
#import "XMPPvCardTempModule.h"
#import "XMPPvCardTemp.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
  static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
  static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

NSString *const kXMPPvCardAvatarElement = @"x";
NSString *const kXMPPvCardAvatarNS = @"vcard-temp:x:update";
NSString *const kXMPPvCardAvatarPhotoElement = @"photo";


@implementation XMPPvCardAvatarModule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Init/dealloc
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)init
{
	// This will cause a crash - it's designed to.
	// Only the init methods listed in XMPPvCardAvatarModule.h are supported.
	
	return [self initWithvCardTempModule:nil dispatchQueue:NULL];
}

- (id)initWithDispatchQueue:(dispatch_queue_t)queue
{
	// This will cause a crash - it's designed to.
	// Only the init methods listed in XMPPvCardAvatarModule.h are supported.
	
	return [self initWithvCardTempModule:nil dispatchQueue:NULL];
}

- (id)initWithvCardTempModule:(XMPPvCardTempModule *)xmppvCardTempModule
{
  return [self initWithvCardTempModule:xmppvCardTempModule dispatchQueue:NULL];
}

- (id)initWithvCardTempModule:(XMPPvCardTempModule *)xmppvCardTempModule dispatchQueue:(dispatch_queue_t)queue
{
	NSParameterAssert(xmppvCardTempModule != nil);

	if ((self = [super initWithDispatchQueue:queue])) {
		_xmppvCardTempModule = xmppvCardTempModule;

		// we don't need to call the storage configureWithParent:queue: method,
		// because the vCardTempModule already did that.
		_moduleStorage = (id <XMPPvCardAvatarStorage>)xmppvCardTempModule.xmppvCardTempModuleStorage;

		[_xmppvCardTempModule addDelegate:self delegateQueue:moduleQueue];
		
		_autoClearMyvcard = YES;
	}
	return self;
}


- (void)dealloc {
	[_xmppvCardTempModule removeDelegate:self];

	_moduleStorage = nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (BOOL)autoClearMyvcard
{
	__block BOOL result = NO;
	
	dispatch_block_t block = ^{
		result = _autoClearMyvcard;
	};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return result;
}

- (void)setAutoClearMyvcard:(BOOL)flag
{
	dispatch_block_t block = ^{
		_autoClearMyvcard = flag;
	};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSData *)photoDataForJID:(XMPPJID *)jid 
{
	// This is a public method, so it may be invoked on any thread/queue.
	// 
	// The vCardTempModule is thread safe.
	// The moduleStorage should be thread safe. (User may be using custom module storage class).
	// The multicastDelegate is NOT thread safe.
	
	__block NSData *photoData;
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		photoData = [_moduleStorage photoDataForJID:jid xmppStream:xmppStream];
		
		if (photoData == nil) 
		{
			[_xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
		}
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return photoData;
}

- (NSString *)phoneNumberForJID:(XMPPJID *)jid
{
    __block NSString *phoneNumber;
    
    dispatch_block_t block = ^{ @autoreleasepool {
		
		phoneNumber = [_moduleStorage phoneNumberForJID:jid xmppStream:xmppStream];
		
		if (phoneNumber == nil){
			[_xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
		}
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return phoneNumber;
    
}

- (NSString *)bareJidStrWithPhone:(NSString *)phone
{
    __block NSString *bareJidStr;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        bareJidStr = [_moduleStorage bareJidStrForPhone:phone xmppStream:xmppStream];
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return bareJidStr;
}

- (NSString *)emailAddressForJID:(XMPPJID *)jid
{
    __block NSString *emailAddress;
    
    dispatch_block_t block = ^{ @autoreleasepool {
		
		emailAddress = [_moduleStorage emailAddressForJID:jid xmppStream:xmppStream];
		
		if (emailAddress == nil){
			[_xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
		}
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return emailAddress;
}

- (NSString *)nickNameForJID:(XMPPJID *)jid
{
    __block NSString *nickName;
    
    dispatch_block_t block = ^{ @autoreleasepool {
		
		nickName = [_moduleStorage nickNameForJID:jid xmppStream:xmppStream];
		
		if (nickName == nil){
			[_xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
		}
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return nickName;
}

- (NSString *)photoURLForBareJidStr:(NSString *)bareJidStr
{
    __block NSString *photoURL;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        XMPPJID *jid = [XMPPJID jidWithString:bareJidStr];
        photoURL = [_moduleStorage photoURLForJID:jid xmppStream:xmppStream];
        
        if (photoURL == nil){
            [_xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
        }
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
    
    return photoURL;
}

#pragma mark - asys methods
- (void)fetchPhotoDataWithBareJidStr:(NSString *)bareJidStr
                     completionBlock:(CompletionBlock)completionBlock
{
    dispatch_block_t block = ^{
        [_xmppvCardTempModule vCardWithBareJidStr:bareJidStr
                                  completionBlock:^(id data, NSError *error) {
                                  
                                      if (!error) {
                                          
                                          XMPPvCardTemp *vCardTemp = (XMPPvCardTemp *)data;
                                          completionBlock(vCardTemp.photo, nil);
                                          
                                      }else{
                                          completionBlock(nil, error);
                                      }
                                  
                                  }];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}
- (void)fetchPhoneNumberWithBareJidStr:(NSString *)bareJidStr
                       completionBlock:(CompletionBlock)completionBlock
{
    dispatch_block_t block = ^{
        [_xmppvCardTempModule vCardWithBareJidStr:bareJidStr
                                  completionBlock:^(id data, NSError *error) {
                                      
                                      if (!error) {
                                          
                                          XMPPvCardTemp *vCardTemp = (XMPPvCardTemp *)data;
                                          completionBlock(vCardTemp.phoneNumber, nil);
                                          
                                      }else{
                                          completionBlock(nil, error);
                                      }
                                      
                                  }];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}
- (void)fetchEmailAddressWithBareJidStr:(NSString *)bareJidStr
                        completionBlock:(CompletionBlock)completionBlock
{
    dispatch_block_t block = ^{
        [_xmppvCardTempModule vCardWithBareJidStr:bareJidStr
                                  completionBlock:^(id data, NSError *error) {
                                      
                                      if (!error) {
                                          
                                          XMPPvCardTemp *vCardTemp = (XMPPvCardTemp *)data;
                                          completionBlock(vCardTemp.emailAddress, nil);
                                          
                                      }else{
                                          completionBlock(nil, error);
                                      }
                                      
                                  }];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}
- (void)fetchNickNameWithBareJidStr:(NSString *)bareJidStr
                    completionBlock:(CompletionBlock)completionBlock
{
    dispatch_block_t block = ^{
        [_xmppvCardTempModule vCardWithBareJidStr:bareJidStr
                                  completionBlock:^(id data, NSError *error) {
                                      
                                      if (!error) {
                                          
                                          XMPPvCardTemp *vCardTemp = (XMPPvCardTemp *)data;
                                          completionBlock(vCardTemp.nickname, nil);
                                          
                                      }else{
                                          completionBlock(nil, error);
                                      }
                                      
                                  }];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}
- (void)fetchPhotoURLWithBareJidStr:(NSString *)bareJidStr
                    completionBlock:(CompletionBlock)completionBlock
{
    dispatch_block_t block = ^{
        [_xmppvCardTempModule vCardWithBareJidStr:bareJidStr
                                  completionBlock:^(id data, NSError *error) {
                                      
                                      if (!error) {
                                          
                                          XMPPvCardTemp *vCardTemp = (XMPPvCardTemp *)data;
                                          completionBlock(vCardTemp.photoURL, nil);
                                          
                                      }else{
                                          completionBlock(nil, error);
                                      }
                                      
                                  }];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}




- (void)vCardWithBareJidStr:(NSString *)bareJidStr completionBlock:(CompletionBlock)completionBlock
{
    dispatch_block_t block = ^{
        [_xmppvCardTempModule vCardWithBareJidStr:bareJidStr completionBlock:completionBlock];
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	XMPPLogTrace();
	
	if(self.autoClearMyvcard)
	{
		/*
		 * XEP-0153 Section 4.2 rule 1
		 *
		 * A client MUST NOT advertise an avatar image without first downloading the current vCard. 
		 * Once it has done this, it MAY advertise an image. 
		 */
		[_moduleStorage clearvCardTempForJID:[sender myJID] xmppStream:sender];
	}
}


- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
	XMPPLogTrace();
	[_xmppvCardTempModule fetchvCardTempForJID:[sender myJID] ignoreStorage:YES];
}


- (XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence {
	XMPPLogTrace();
    
	NSXMLElement *currentXElement = [presence elementForName:kXMPPvCardAvatarElement xmlns:kXMPPvCardAvatarNS];
	
	//If there is already a x element then remove it
	if(currentXElement)
	{
	    NSUInteger currentXElementIndex = [[presence children] indexOfObject:currentXElement];
	    
	    if(currentXElementIndex != NSNotFound)
	    {
	        [presence removeChildAtIndex:currentXElementIndex];
	    }
	}
	// add our photo info to the presence stanza
	NSXMLElement *photoElement = nil;
	NSXMLElement *xElement = [NSXMLElement elementWithName:kXMPPvCardAvatarElement xmlns:kXMPPvCardAvatarNS];

	NSString *photoHash = [_moduleStorage photoHashForJID:[sender myJID] xmppStream:sender];

	if (photoHash != nil)
    {
	    photoElement = [NSXMLElement elementWithName:kXMPPvCardAvatarPhotoElement stringValue:photoHash];
	} else {
	    photoElement = [NSXMLElement elementWithName:kXMPPvCardAvatarPhotoElement];
	}

	[xElement addChild:photoElement];
	[presence addChild:xElement];
    
	// Question: If photoElement is nil, should we be adding xElement?
	
	return presence;
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence  {
	XMPPLogTrace();

	NSXMLElement *xElement = [presence elementForName:kXMPPvCardAvatarElement xmlns:kXMPPvCardAvatarNS];

	if (xElement == nil) {
		return;
	}

	NSXMLElement *photoElement = [xElement elementForName:kXMPPvCardAvatarPhotoElement];

	if (photoElement == nil) {
		return;
	}
    
    NSString *photoHash = [photoElement stringValue];

	XMPPJID *jid = [presence from];
    
    NSString *savedPhotoHash = [_moduleStorage photoHashForJID:jid xmppStream:xmppStream];

	// check the hash
	if ([photoHash caseInsensitiveCompare:savedPhotoHash] != NSOrderedSame
        && !([photoHash length] == 0 && [savedPhotoHash length] == 0)) {
		[_xmppvCardTempModule fetchvCardTempForJID:jid ignoreStorage:YES];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPvCardTempModuleDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule 
        didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp 
                     forJID:(XMPPJID *)jid
{
	XMPPLogTrace();
	
	if (vCardTemp.photo != nil)
	{
	#if TARGET_OS_IPHONE
		UIImage *photo = [UIImage imageWithData:vCardTemp.photo];
	#else
		NSImage *photo = [[NSImage alloc] initWithData:vCardTemp.photo];
	#endif
		
		if (photo != nil)
		{
			[multicastDelegate xmppvCardAvatarModule:self
			                         didReceivePhoto:photo
			                                  forJID:jid];
		}
	}
	
	/*
	 * XEP-0153 4.1.3
	 * If the client subsequently obtains an avatar image (e.g., by updating or retrieving the vCard), 
	 * it SHOULD then publish a new <presence/> stanza with character data in the <photo/> element.
	 */
    
	if ([[xmppStream myJID] isEqualToJID:jid options:XMPPJIDCompareBare])
	{
		XMPPPresence *presence = xmppStream.myPresence;
        
        if(presence)
        {
            [xmppStream sendElement:presence];
        }


	}
}

- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule{
    //The vCard has been updated on the server so we need to cache it
    [_xmppvCardTempModule fetchvCardTempForJID:[xmppStream myJID] ignoreStorage:YES];
}

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error{
		//The vCard failed to update so we fetch the current one from the server
    [_xmppvCardTempModule fetchvCardTempForJID:[xmppStream myJID] ignoreStorage:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Getter/setter
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize xmppvCardTempModule = _xmppvCardTempModule;


@end

@implementation XMPPvCardAvatarModule (Deprecated)

- (void)requestvCardWithBareJidStr:(NSString *)bareJidStr completionBlock:(CompletionBlock)completionBlock
{
    [self vCardWithBareJidStr:bareJidStr
              completionBlock:completionBlock];
}

@end
