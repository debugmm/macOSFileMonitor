//
//  TBFileMonitor.m
//  FileSystemDemo
//
//  Created by wujungao on 2019/1/15.
//  Copyright © 2019 wujungao. All rights reserved.
//

#import "TBFileMonitor.h"

//#import <ReactiveObjC/ReactiveObjC.h>

//define
#define PathValueError (@"path_value_error")
#define OperationQueueError (@"operation_queue_create_error")
#define FileMonitorError (@"file_monitor_create_error")

#define ErrorCode (404)

@interface TBFileMonitor(){
    
    NSURL *_presentedItemURL;
    NSOperationQueue *_presentedItemOperationQueue;
}

@property(nonatomic,strong,nullable)NSURL *itemPresentingURL;

@end

@implementation TBFileMonitor

@dynamic presentedItemOperationQueue;
@dynamic presentedItemURL;

#pragma mark - Lifecycle
-(instancetype)init{
    self=[super init];
    if(self){
    }
    
    return self;
}

-(void)dealloc{
    [self removeMonitor];
}

#pragma mark -
+(nullable TBFileMonitor *)monitorFileURL:(nonnull NSURL*)url
                                    error:(NSError * _Nullable __autoreleasing *)er{
    
    TBFileMonitor *fm=[TBFileMonitor fileMonitorGenerator:url error:er];
    
    return fm;
}

+(nullable TBFileMonitor *)monitorFilePath:(nonnull NSString *)path
                                     error:(NSError * _Nullable __autoreleasing *)er{
    
    //check url
    if(![TBFileMonitor isValidatePathValue:path error:er]){
        return nil;
    }
    
    NSURL *furl=[NSURL fileURLWithPath:path];
    
    return [TBFileMonitor fileMonitorGenerator:furl error:er];
}

#pragma mark -
-(void)removeMonitor{
    
    [self removeFilePresenterFromCoordinator];
}

#pragma mark - private methods
+(nullable TBFileMonitor *)fileMonitorGenerator:(nonnull NSURL *)url error:(NSError * _Nullable __autoreleasing *)er{
    
    //check url
    if(![TBFileMonitor isValidatePathValue:url error:er]){
        return nil;
    }
    
    NSOperationQueue *q=[TBFileMonitor createOperationQueueError:er];
    if(q==nil){
        return nil;
    }
    
    //create file monitor
    TBFileMonitor *fm=[[TBFileMonitor alloc] init];
    
    //config file monitor
    [fm setPresentedItemURL:url];
    [fm setPresentedItemOperationQueue:q];
    fm.itemPresentingURL=url;
    
    //add file monitor to cordinator
    [fm addFilePresenterToCoordinator:fm];
    
    return fm;
}

-(void)addFilePresenterToCoordinator:(id<NSFilePresenter>)filePresenter{
    
    if(filePresenter==nil ||
       filePresenter==NULL ||
       ![filePresenter conformsToProtocol:@protocol(NSFilePresenter)]){
        return;
    }
    
    [NSFileCoordinator addFilePresenter:filePresenter];
}

-(void)resumeMonitor{
    
    [self addFilePresenterToCoordinator:self];
}

-(void)removeFilePresenterFromCoordinator{
    
    [NSFileCoordinator removeFilePresenter:self];
}

#pragma mark - help methods
+(BOOL)isValidatePathValue:(id)pathValue error:(NSError * _Nullable __autoreleasing *)er{
    
    BOOL isValidate=YES;
    if(pathValue==nil ||
       pathValue==NULL ||
       (![pathValue isKindOfClass:[NSString class]] && ![pathValue isKindOfClass:[NSURL class]])){
        
        if(er){
            *er=[NSError errorWithDomain:PathValueError code:ErrorCode userInfo:nil];
        }
        
        isValidate=NO;
    }
    
    return isValidate;
}

+(nullable NSOperationQueue *)createOperationQueueError:(NSError * _Nullable __autoreleasing *)er{
    
    NSOperationQueue *q=[[NSOperationQueue alloc] init];
    if(q==nil || q==NULL){
        
        if(er){
            *er=[NSError errorWithDomain:OperationQueueError code:ErrorCode userInfo:nil];
        }
        return nil;
    }
    
    q.maxConcurrentOperationCount=1;
    q.suspended=NO;
    
    return q;
}

+(nullable NSURL *)createFileURLFromPathString:(nonnull NSString *)pathString{
    
    NSURL *url=[NSURL fileURLWithPath:pathString];
    
    return url;
}

-(void)updateItemPresentingURL:(nullable NSURL *)newURL{
    
    self.itemPresentingURL=newURL;
}

#pragma mark - NSFilePresenter Protocol
- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler{
    completionHandler(nil);
}

-(void)presentedItemDidMoveToURL:(NSURL *)newURL{
    
    NSString *oldName=[self.itemPresentingURL.absoluteString.lastPathComponent stringByRemovingPercentEncoding];
    NSString *newName=[newURL.absoluteString.lastPathComponent stringByRemovingPercentEncoding];
    if([oldName isEqualToString:newName]){
        //item has been moved
        if(self.fileMonitorDelegate &&
           [self.fileMonitorDelegate respondsToSelector:@selector(itemMoveToURL:)]){
            
            [self.fileMonitorDelegate itemMoveToURL:newURL];
        }
    }
    else{
        //item has been renamed
        if(self.fileMonitorDelegate &&
           [self.fileMonitorDelegate respondsToSelector:@selector(fileRenameToName:)]){
            
            [self.fileMonitorDelegate fileRenameToName:newName];
        }
    }
    
    [self updateItemPresentingURL:newURL];
}

#pragma  mark -
- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError * _Nullable))completionHandler{
    completionHandler(nil);
}

-(void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL{
}

#pragma mark - property
-(void)setPresentedItemURL:(NSURL *)presentedItemURL{
    _presentedItemURL=presentedItemURL;
}

-(NSURL *)presentedItemURL{
    return _presentedItemURL;
}

-(void)setPresentedItemOperationQueue:(NSOperationQueue *)presentedItemOperationQueue{
    _presentedItemOperationQueue=presentedItemOperationQueue;
}

-(NSOperationQueue *)presentedItemOperationQueue{
    return _presentedItemOperationQueue;
}

@end
