//
//  TBFileMonitor.h
//  FileSystemDemo
//
//  Created by wujungao on 2019/1/15.
//  Copyright © 2019 wujungao. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @brief file monitor protocol.
 any object which wants receiving file-modification message,should implement the protocol methods.
 */
@protocol TBFileMonitorProtocol <NSObject>

@optional

/**
 @brief file has been renamed to a new Name

 @param newName a new file name
 */
-(void)fileRenameToName:(nonnull NSString *)newName;


/**
 @brief item(file or directory) has been moved to new file url(new url-new file path)

 @param newURL new file url
 */
-(void)itemMoveToURL:(nonnull NSURL *)newURL;

/**
 @brief 被监控的文件夹下，有文件被创建。被创建的文件路径是newFullPath（包括文件名）

 @param newFullPath 被创建的文件完整路径
 */
-(void)itemCreatedAtPath:(nonnull NSString *)newFullPath;

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
