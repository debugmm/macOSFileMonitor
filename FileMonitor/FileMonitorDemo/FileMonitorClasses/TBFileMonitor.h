//
//  TBFileMonitor.h
//  FileSystemDemo
//
//  Created by wujungao on 2019/1/15.
//  Copyright © 2019 wujungao. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @brief 文件 or 文件夹监控协议
 */
@protocol TBFileMonitorProtocol <NSObject>

@optional

/**
 @brief 被监控的文件 or 文件夹被重命名了。文件新名字为：newName

 @param newName 被重名明后的文件名字
 */
-(void)itemRenameToName:(nonnull NSString *)newName;

/**
 @brief 被监控的文件 or 文件夹被移动到了。文件的新路径为：newURL

 @param newURL 被移动之后的新路径
 
 */
-(void)itemMoveToURL:(nonnull NSURL *)newURL;

#pragma mark - be monitored directory
/**
 @brief 被监控的文件夹（注意：是文件夹），下面有文件被创建

 @param newFullPath 被创建的文件完整路径（文件在本地的绝对路径）
 */
-(void)itemCreatedAtPath:(nonnull NSString *)newFullPath;

/**
 @brief 被监控的文件夹（注意：是文件夹），下面有文件被删除

 @param originFullPath 被删除文件原路径（本地绝对路径）
 */
-(void)itemDeletedWithOriginItemPath:(nonnull NSString *)originFullPath;

@end

NS_ASSUME_NONNULL_BEGIN

/**
 @brief file-modification monitor class.
 it will be used to monitor file and receive file-modification message.
 */
@interface TBFileMonitor : NSObject <NSFilePresenter>

#pragma mark - property
/**
 @brief file monitor delegate(the delegate can receive file move and rename message).
 any intesting file-modification message object should set self as file monitor delegate.
 */
@property(nonatomic,weak,nullable)id <TBFileMonitorProtocol> fileMonitorDelegate;

#pragma mark - method
/**
 @brief create file monitor instance with file url

 @param url file url
 @param er NSError pointer type
 @return file monitor instance
 */
+(nullable TBFileMonitor *)monitorFileURL:(nonnull NSURL*)url
                                    error:(NSError * _Nullable __autoreleasing *)er;


/**
 @brief create file monitor instance with file path

 @param path file path
 @param er NSError pointer type
 @return file monitor instance
 */
+(nullable TBFileMonitor *)monitorFilePath:(nonnull NSString *)path
                                     error:(NSError * _Nullable __autoreleasing *)er;

#pragma mark - instance method

/**
 @brief 停止监听文件
 */
-(void)stopMonitor;

/**
 @brief 开始监听文件
 */
-(void)startMonitor;

@end

NS_ASSUME_NONNULL_END
