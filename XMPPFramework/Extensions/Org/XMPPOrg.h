//
//  XMPPOrganization.h
//  XMPP_Project
//
//  Created by Peter Lee on 15/5/22.
//  Copyright (c) 2015年 Peter Lee. All rights reserved.
//

#import "XMPP.h"

@protocol XMPPOrgDelegate;
@protocol XMPPOrgStorage;

@class XMPPOrgUserCoreDataStorageObject;

@interface XMPPOrg : XMPPModule
{
    __strong id <XMPPOrgStorage> _xmppOrgStorage;
}

@property (strong, readonly) id <XMPPOrgStorage> xmppOrgStorage;

@property (assign) BOOL autoFetchOrgList;
@property (assign) BOOL autoFetchOrgTemplateList;

- (id)initWithOrganizationStorage:(id <XMPPOrgStorage>)storage;
- (id)initWithOrganizationStorage:(id <XMPPOrgStorage>)storage dispatchQueue:(dispatch_queue_t)queue;

#pragma mark - 获取所有项目
/**
 *  向服务器请求所有的项目
 */
- (void)requestServerAllOrgList;

/**
 *  向本地请求所有的项目，并返回结果
 *
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllOrgListWithBlock:(CompletionBlock)completionBlock;

/**
 *  清除本地所有项目信息
 */
- (void)clearAllOrgs;

#pragma mark - 获取所有模板
/**
 *  向服务器请求所有模板
 */
- (void)requestServerAllTemplates;

/**
 *  从本地数据库请求所有模板信息，并返回
 *
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllTemplatesWithBlock:(CompletionBlock)completionBlock;

/**
 *  清除所有模板
 */
- (void)clearAllTemplates;

#pragma mark - 获取一个组织的所有职位信息

/**
 *  向服务器请求一个项目或者模板的所有职位信息
 *
 *  @param orgId      项目或者模板id
 *  @param isTemplate 是否是模板标志
 */
- (void)requestServerAllPositionListWithOrgId:(NSString *)orgId
                                   isTemplate:(BOOL)isTemplate;

/**
 *  在本地取出一个项目或者模板的职位信息
 *
 *  @param orgId           项目或者模板id
 *  @param isTemplate      是否模板标志
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllPositionListWithOrgId:(NSString *)orgId
                               isTemplate:(BOOL)isTemplate
                          completionBlock:(CompletionBlock)completionBlock;
 
#pragma mark - 获取一个组织的所有成员信息
/**
 *  向服务器请求一个项目的成员信息
 *
 *  @param orgId 项目id
 */
- (void)requestServerAllUserListWithOrgId:(NSString *)orgId;

/**
 *  在本地取出一个项目的所有成员信息
 *
 *  @param orgId           项目id
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllUserListWithOrgId:(NSString *)orgId
                      completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 获取一个组织的所有关键组织的id
/**
 *  向服务器请求一个项目的所有关联组织的信息
 *
 *  @param orgId 项目id
 */
- (void)requestServerAllRelationListWithOrgId:(NSString *)orgId;

/**
 *  在本地取出一个项目的所有关联组织信息
 *
 *  @param orgId           项目id
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllRelationListWithOrgId:(NSString *)orgId
                          completionBlock:(CompletionBlock)completionBlock;


#pragma mark - 获取一个组织或者关联组织的所有职位信息
/**
 *  向服务器获取一个组织或者关联组织的所有职位信息
 *
 *  @param orgId         本项目id
 *  @param relationOrgId 关联项目id
 *  @param isTemplate    是否是模板
 */
- (void)requestServerAllPositionListWithOrgId:(NSString *)orgId 
                                relationOrgId:(NSString *)relationOrgId
                                   isTemplate:(BOOL)isTemplate;

/**
 *  本地取出一个组织或者关联组织的所有职位信息
 *
 *  @param orgId           本项目id
 *  @param relationOrgId   关联项目id
 *  @param isTemplate      是否是模板
 *  @param completionBlock 回掉block(执行在主线程队列)
 */
- (void)requestDBAllPositionListWithOrgId:(NSString *)orgId
                            relationOrgId:(NSString *)relationOrgId
                               isTemplate:(BOOL)isTemplate
                          completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 获取一个组织的所有成员信息
/**
 *  向服务器请求一个组织关联组织的人员信息
 *
 *  @param orgId         本组织id
 *  @param relationOrgId 关联组织id
 */
- (void)requestServerAllUserListWithOrgId:(NSString *)orgId
                            relationOrgId:(NSString *)relationOrgId;

/**
 *  在本地取出一个关联项目的所有成员信息
 *
 *  @param orgId           本组织id
 *  @param relationOrgId   关联组织id
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllUserListWithOrgId:(NSString *)orgId
                        relationOrgId:(NSString *)relationOrgId
                      completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 验证组织name

/**
 *  检查项目名称是否已经存在
 *
 *  @param name            项目名称
 *  @param completionBlock 回掉block
 */
- (void)checkOrgName:(NSString *)name
     completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 创建组织
/**
 *  创建项目
 *
 *  @param name            名称
 *  @param templateId      模板id
 *  @param jobId           自己的职位id
 *  @param completionBlock 回掉block
 */
- (void)createOrgWithName:(NSString *)name
               templateId:(NSString *)templateId
                selfJobId:(NSString *)jobId
          completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 结束组织
/**
 *  结束一个项目
 *
 *  @param orgId           项目id
 *  @param completionBlock 回掉block
 */
- (void)endOrgWithId:(NSString *)orgId
     completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 查询自己可以添加的职位（自己的子职位）列表
/**
 *  从本地取出一个职位的所有子职位
 *
 *  @param ptId            职位id
 *  @param orgId           项目id
 *  @param completionBlock 回掉block
 */
- (void)requestDBAllSubPositionsWithPtId:(NSString *)ptId
                                   orgId:(NSString *)orgId
                         completionBlock:(CompletionBlock)completionBlock;

/**
 *  向服务器查询一个职位的所有子职位
 *
 *  @param orgId           项目id
 *  @param ptId            职位id
 *  @param completionBlock 回掉block
 */
- (void)requestServerAllSubPositionsWithOrgId:(NSString *)orgId
                                         ptId:(NSString *)ptId
                              completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 查询自己可以添加的成员列表
/**
 *  获取一个成员的所有的子职位
 *
 *  @param orgId               项目id
 *  @param superUserBareJidStr 成员的jid
 *
 *  @return 所有子职位信息
 */
- (id)requestDBAllSubUsersWithOrgId:(NSString *)orgId superUserBareJidStr:(NSString *)superUserBareJidStr;

/**
 *  获取自己的所有子职位
 *
 *  @param orgId 项目id
 *
 *  @return 自己的所有子职位信息
 */
- (id)requestDBAllSubUsersWithOrgId:(NSString *)orgId;

/**
 *  在本地数据库查询一个项目的管理员
 *
 *  @param orgId 项目id
 *
 *  @return 管理员的对象（CoreData NSmanagerObject）
 */
- (id)requestDBAdminInfoFromOrgId:(NSString *)orgId;


#pragma mark - 创建新的职位信息
/**
 *  创建新的职位信息
 *
 *  @param orgId           组织id
 *  @param parentPtId      职位所属上级职位的id
 *  @param ptName          职位名称
 *  @param dpName          职位所属部门名称
 *  @param dpLevel         职位所属部门等级
 *  @param completionBlock 返回结果block
 */
- (void)createPositionWithOrgId:(NSString *)orgId
                      adminPtId:(NSString *)adminPtId
                     parentPtId:(NSString *)parentPtId
                         ptName:(NSString *)ptName
                         dpName:(NSString *)dpName
                        dpLevel:(NSInteger)dpLevel
                completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 为某个组织加人
- (void)addUsers:(NSArray *)userBareJids
         joinOrg:(NSString *)orgId
  withPositionId:(NSString *)ptId
 completionBlock:(CompletionBlock)completionBlock;

- (void)fillOrg:(NSString *)orgId
 withPositionId:(NSString *)ptId
  callBackBlock:(CompletionBlock)completionBlock
      withUsers:(NSString *)userBareJid1, ... NS_REQUIRES_NIL_TERMINATION;

#pragma mark - 从某个组织删人
- (void)removeUserBareJidStr:(NSString *)userBareJidStr
                        ptId:(NSString *)ptId
                     formOrg:(NSString *)orgId
                withSelfPtId:(NSString *)selfPtId
             completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 订阅某个组织
- (void)subcribeOrgRequestWithSelfOrgId:(NSString *)selfOrgId
                             otherOrgId:(NSString *)otherOrgId
                            description:(NSString *)description
                        completionBlock:(CompletionBlock)completionBlock;

- (void)acceptSubcribeRequestWithSelfOrgId:(NSString *)selfOrgId
                            otherOrgId:(NSString *)otherOrgId
                           description:(NSString *)description
                       completionBlock:(CompletionBlock)completionBlock;

- (void)refuseSubcribeRequestWithSelfOrgId:(NSString *)selfOrgId
                                otherOrgId:(NSString *)otherOrgId
                               description:(NSString *)description
                           completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 取消订阅某个组织
- (void)removeSubcribeOrg:(NSString *)orgId
                  formOrg:(NSString *)formOrg
              description:(NSString *)description
          completionBlock:(CompletionBlock)completionBlock;


#pragma mark - 搜索某个组织
-(void)searchOrgWithName:(NSString *)orgName
         completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 根据某个组织的id获取这个组织的信息
- (void)requestServerOrgWithOrgId:(NSString *)orgId;
- (void)requestDBOrgWithOrgId:(NSString *)orgId
              completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 根据某个组织的id查询他的部门信息
- (void)requestDBOrgDepartmentWithOrgId:(NSString *)orgId
                        completionBlock:(CompletionBlock)completionBlock;

- (void)requestDBOrgDepartmentWithOrgId:(NSString *)orgId
                          relationOrgId:(NSString *)relationOrgId
                        completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 查询成员列表
- (id)requestDBAllUsersWithOrgId:(NSString *)orgId;
- (id)requestDBUserPositionNameWithOrgId:(NSString *)orgId bareJidStr:(NSString *)bareJidStr;
- (id)requestDBUserPositionWithOrgId:(NSString *)orgId bareJidStr:(NSString *)bareJidStr;

#pragma mark - 按部门名称查询部门成员列表
- (id)requestDBAllUsersWithOrgId:(NSString *)orgId 
                          dpName:(NSString *)dpName
                       ascending:(BOOL)ascending;

#pragma mark - 按部门名称查询部门职位列表
- (id)requestDBAllPositionsWithOrgId:(NSString *)orgId
                              dpName:(NSString *)dpName
                           ascending:(BOOL)ascending;

#pragma mark - 根据某个组织的id查询他在数据库中的名称
- (void)requestDBOrgNameWithOrgId:(NSString *)orgId
                  completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 查询最近的正在运行的项目信息
- (void)requestDBRecentOrgWithCompletionBlock:(CompletionBlock)completionBlock;

#pragma mark - 根据某个关联组织的id查询他在数据库中的名称
- (void)requestDBRelationOrgNameWithRelationOrgId:(NSString *)relationOrgId
                                            orgId:(NSString *)orgId
                                  completionBlock:(CompletionBlock)completionBlock;

- (void)relationOrgPhotoWithrelationOrgId:(NSString *)relationOrgId
                                    orgId:(NSString *)orgId
                          completionBlock:(CompletionBlock)completionBlock;

#pragma mark - 获取一个关联组组的详细信息
- (void)requestServerRelationOrgWithRelationId:(NSString *)relationId
                                         orgId:(NSString *)orgId;

- (void)requestDBRelationOrgWithRelationId:(NSString *)relationId
                                     orgId:(NSString *)orgId
                           completionBlock:(CompletionBlock)completionBlock;


/**
 *  自己是否是该工程的admin
 *
 *  @param orgId 项目id
 *
 *  @return YES:如果自己是该项目的管理员，NO:自己不是该项目管理员
 */
- (BOOL)isSelfAdminOfOrgWithOrgId:(NSString *)orgId;

/**
 *  查询某个用户是否在某个组织中
 *
 *  @param bareJidStr 被查询用户的jid
 *  @param orgId      被查用户指定的项目id
 *
 *  @return YES：如果该用户在改组织中，NO：该用户不在该项目中
 */
- (BOOL)existedUserWithBareJidStr:(NSString *)bareJidStr inOrgWithId:(NSString *)orgId;

/**
 *  根据项目组织id或者模板id获取该项目或者模板的头像
 *
 *  @param orgId           项目或者模板的头像
 *  @param isTemplate      请求的是否是模板的头像
 *  @param completionBlock 回掉block
 */
- (void)requestDBOrgPhotoWithOrgId:(NSString *)orgId
                        isTemplate:(BOOL)isTemplate
                   completionBlock:(CompletionBlock)completionBlock;

/**
 *  获取模板的hash
 *
 *  @param completionBlock 回掉block
 */
-(void)getTempHashWithcompletionBlock:(CompletionBlock)completionBlock;

/**
 *  根据组织id 设置组织的头像
 *
 *  @param orgId           项目id
 *  @param fileId          文件的fileId
 *  @param completionBlock 回掉block
 */
- (void)setOrgPhotoWithOrgId:(NSString *)orgId
                      fileId:(NSString *)fileId
             completionBlock:(CompletionBlock)completionBlock;
/**
 *  查询一个人的所有正在进行的任务
 *
 *  @param orgId             当前任务所属的项目id
 *  @param bareJidStr        这个人的jid
 *  @param page              是否需要分页
 *  @param countOfDataInPage 分页数量，如果不要分页 改数字无效
 *  @param completionBlock   回掉的数据源block
 */
- (void)requestServerAllTasksWithOrgId:(NSString *)orgId
                            bareJidStr:(NSString *)bareJidStr
                                  page:(BOOL)page
                           countOfPage:(NSInteger)countOfPage
                     countOfDataInPage:(NSInteger)countOfDataInPage
                       completionBlock:(CompletionBlock)completionBlock;


@end


// XMPPOrganizationDelegate
@protocol XMPPOrgDelegate <NSObject>

@required

@optional

- (void)xmppOrg:(XMPPOrg *)xmppOrg didReceiveSubcribeRequestFromOrgId:(NSString *)fromOrgId fromOrgName:(NSString *)fromOrgName toOrgId:(NSString *)toOrgId;
- (void)xmppOrg:(XMPPOrg *)xmppOrg didReceiveAcceptSubcribeFromOrgId:(NSString *)fromOrgId fromOrgName:(NSString *)fromOrgName toOrgId:(NSString *)toOrgId;
- (void)xmppOrg:(XMPPOrg *)xmppOrg didReceiveRefuseSubcribeFromOrgId:(NSString *)fromOrgId fromOrgName:(NSString *)fromOrgName toOrgId:(NSString *)toOrgId;
- (void)xmppOrg:(XMPPOrg *)xmppOrg didReceiveRemoveSubcribeFromOrgId:(NSString *)fromOrgId fromOrgName:(NSString *)fromOrgName toOrgId:(NSString *)toOrgId;

@end


// XMPPOrganizationStorage
@protocol XMPPOrgStorage <NSObject>

@required

- (BOOL)configureWithParent:(XMPPOrg *)aParent queue:(dispatch_queue_t)queue;

@optional

- (void)clearOrgsNotInOrgIds:(NSArray *)orgIds isTemplate:(BOOL)isTemplate xmppStream:(XMPPStream *)stream;
- (void)clearOrgWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (void)clearAllOrgWithXMPPStream:(XMPPStream *)stream;
- (void)clearAllTemplatesWithXMPPStream:(XMPPStream *)stream;
- (id)allOrgTemplatesWithXMPPStream:(XMPPStream *)stream;
- (id)allOrgsWithXMPPStream:(XMPPStream *)stream;
- (id)orgWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (id)recentOrgWithXMPPStream:(XMPPStream *)stream;
- (id)relationOrgWithRelationId:(NSString *)relationId orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (id)orgPositionsWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (id)orgDepartmentWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (id)orgUsersWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (id)orgPhotoWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (id)subUsersWithOrgId:(NSString *)orgId superUserBareJidStr:(NSString *)superUserBareJidStr xmppStream:(XMPPStream *)stream;

- (id)usersInDepartmentWithDpName:(NSString *)dpName
                            orgId:(NSString *)orgId
                        ascending:(BOOL)ascending
                       xmppStream:(XMPPStream *)stream;

- (id)positionsInDepartmentWithDpName:(NSString *)dpName
                                orgId:(NSString *)orgId
                            ascending:(BOOL)ascending
                           xmppStream:(XMPPStream *)stream;

- (id)newUsersWithOrgId:(NSString *)orgId userIds:(NSArray *)userIds xmppStream:(XMPPStream *)stream;

- (id)orgRelationsWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (void)insertOrUpdateOrgInDBWith:(NSDictionary *)dic
                       isTemplate:(BOOL)isTemplate
                       xmppStream:(XMPPStream *)stream
                        userBlock:(void (^)(NSString *orgId))userBlock
                    positionBlock:(void (^)(NSString *orgId))positionBlock
                    relationBlock:(void (^)(NSString *orgId))relationBlock;

- (void)insertNewCreateOrgnDBWith:(NSDictionary *)dic
                       xmppStream:(XMPPStream *)stream
                        userBlock:(void (^)(NSString *orgId))userBlock
                    positionBlock:(void (^)(NSString *orgId))positionBlock
                    relationBlock:(void (^)(NSString *orgId))relationBlock;

- (void)clearUsersWithOrgId:(NSString *)orgId  xmppStream:(XMPPStream *)stream;
- (void)clearUsersNotInUserJidStrs:(NSArray *)userJidStrs orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (void)deleteUserWithUserJidStr:(NSString *)userJidStr orgId:(NSString *)orgId  xmppStream:(XMPPStream *)stream;
- (void)deleteUserWithUserBareJidStrs:(NSArray *)userBareJidStrs fromOrgWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (void)insertOrUpdateUserInDBWithOrgId:(NSString *)orgId dic:(NSDictionary *)dic xmppStream:(XMPPStream *)stream;
 
- (void)clearPositionsWithOrgId:(NSString *)orgId  xmppStream:(XMPPStream *)stream;
- (void)clearPositionsNotInPtIds:(NSArray *)ptIds  orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (void)insertOrUpdatePositionInDBWithOrgId:(NSString *)orgId dic:(NSDictionary *)dic xmppStream:(XMPPStream *)stream;

- (void)clearRelationsWithOrgId:(NSString *)orgId  xmppStream:(XMPPStream *)stream;
/*- (void)insertOrUpdateRelationInDBWithOrgId:(NSString *)orgId dic:(NSDictionary *)dic xmppStream:(XMPPStream *)stream;*/
- (void)insertOrUpdateRelationInDBWithOrgId:(NSString *)orgId
                                        dic:(NSDictionary *)dic
                                 xmppStream:(XMPPStream *)stream
                                  userBlock:(void (^)(NSString *orgId, NSString *relationOrgId))userBlock
                              positionBlock:(void (^)(NSString *orgId,  NSString *relationOrgId))positionBlock;

- (id)endOrgWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (id)positionNameWithOrgId:(NSString *)orgId bareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream;
- (id)positionWithOrgId:(NSString *)orgId bareJidStr:(NSString *)bareJidStr xmppStream:(XMPPStream *)stream;
- (id)subPositionsWithPtId:(NSString *)ptId orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (id)positionWithPtId:(NSString *)ptId orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (BOOL)isAdminWithUser:(NSString *)userBareJidStr orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (BOOL)existedUserWithBareJidStr:(NSString *)bareJidStr orgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (id)endOrgWithOrgId:(NSString *)orgId orgEndTime:(NSDate *)orgEndTime xmppStream:(XMPPStream *)stream;
- (void)comparePositionInfoWithOrgId:(NSString *)orgId
                         positionTag:(NSString *)positionTag
                          xmppStream:(XMPPStream *)stream
                        refreshBlock:(void (^)(NSString *orgId))refreshBlock;
- (void)updateUserTagWithOrgId:(NSString *)orgId
                       userTag:(NSString *)userTag
                    xmppStream:(XMPPStream *)stream
                  pullOrgBlock:(void (^)(NSString *orgId))pullOrgBlock;
- (void)updateRelationShipTagWithOrgId:(NSString *)orgId
                       relationShipTag:(NSString *)relationShipTag
                            xmppStream:(XMPPStream *)stream;

- (void)insertSubcribeObjectWithDic:(NSDictionary *)dic xmppStream:(XMPPStream *)stream;
- (void)updateSubcribeObjectWithDic:(NSDictionary *)dic accept:(BOOL)accept xmppStream:(XMPPStream *)stream;
- (void)addOrgId:(NSString *)fromOrgId orgName:(NSString *)formOrgName toOrgId:(NSString *)toTogId xmppStream:(XMPPStream *)stream;
- (void)removeOrgId:(NSString *)removeOrgId fromOrgId:(NSString *)fromOrgId xmppStream:(XMPPStream *)stream;

// 设置头像
- (void)setPhotoURL:(NSString *)photoURL forOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;
- (id)photoURLWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (BOOL)bareJidStr:(NSString *)bareJidStr isSubPositionOfBareJidStr:(NSString *)fatherBareJidStr inOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

- (id)adminBareJidStrWithOrgId:(NSString *)orgId xmppStream:(XMPPStream *)stream;

@end
