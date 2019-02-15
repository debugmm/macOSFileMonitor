//
//  TBFileMonitor.m
//  FileSystemDemo
//
//  Created by wujungao on 2019/1/15.
//  Copyright © 2019 wujungao. All rights reserved.
//

#import "TBFileMonitor.h"

#import <CoreServices/CoreServices.h>

#ifdef DEBUG

#define DLog(fmt, ...) NSLog((@"[文件名:%s]\n" "[消息名:%s]\n" "[行号:%d] \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else

#define NSLog(...)
#define DLog(...)

#endif

//define
#define PathValueError (@"path_value_error")
#define OperationQueueError (@"operation_queue_create_error")
#define FileMonitorError (@"file_monitor_create_error")

#define ErrorCode (404)
#define FSEventLatencyTime (5)

static void fsevents_callback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@interface TBFileMonitor(){
    
    NSURL *_presentedItemURL;
    NSOperationQueue *_presentedItemOperationQueue;
}

@property(nonatomic,strong,nullable)NSURL *itemPresentingURL;

@property(nonatomic,assign)FSEventStreamRef fsEventStream;
@property(nonatomic,nullable,copy)NSString *fsEventMonitorPathDirectory;//通过

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
    [self destroyFSStream];
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
-(void)stopMonitor{
    
    self.presentedItemOperationQueue.suspended=YES;
    
    if(self.fsEventStream){
        FSEventStreamStop(self.fsEventStream);
    }
    
    [self removeFilePresenterFromCoordinator];
}

-(void)startMonitor{
    
    self.presentedItemOperationQueue.suspended=NO;
    
    if(self.fsEventStream){
        FSEventStreamStart(self.fsEventStream);
    }
}

#pragma mark - private methods
-(void)destroyFSStream{
    
    [self stopMonitor];
    if(self.fsEventStream){
        FSEventStreamInvalidate(self.fsEventStream);
        FSEventStreamRelease(self.fsEventStream);
        self.fsEventStream=NULL;
    }
}

#pragma mark -
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
    
    BOOL isDir=NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir]){
        if(isDir){
            fm.fsEventMonitorPathDirectory=url.path;
            [fm initConfigFSEvent];
        }
    }
    
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

#pragma mark - config fs event
-(void)initConfigFSEvent{
    
    if(self.fsEventStream!=nil && self.fsEventStream!=NULL){
        
        FSEventStreamScheduleWithRunLoop(self.fsEventStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    }
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
    q.suspended=YES;
    
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
           [self.fileMonitorDelegate respondsToSelector:@selector(itemRenameToName:)]){
            
            [self.fileMonitorDelegate itemRenameToName:newName];
        }
    }
    
    [self updateItemPresentingURL:newURL];
}

#pragma  mark -
- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError * _Nullable))completionHandler{
    completionHandler(nil);
//    NSLog(@"");
}

-(void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL{
//    NSLog(@"");
}

#pragma mark - fs event call back
//fsevent事件，FSEventStreamEventFlags声明的flag有时候并非与名字相对应
//比如创建了文件，但是被创建的文件发生的事件并非创建，而是rename 或者是文件删除事件 remove
//因此，为了统一起见使用了：kFSEventStreamEventFlagItemIsFile，任何文件都会走进kFSEventStreamEventFlagItemIsFile标记
void fsevents_callback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]){
    
    NSArray *pathArr = (__bridge NSArray*)eventPaths;
    TBFileMonitor *ff=(__bridge TBFileMonitor *)clientCallBackInfo;
    
    for (int i=0; i<numEvents; i++) {
        
        FSEventStreamEventFlags flagg=(eventFlags[i]);
        NSString *filepath=[pathArr objectAtIndex:i];
        
        //过滤系统（Finder）引起的文件事件
        if([TBFileMonitor isSystemFileEvent:filepath.lastPathComponent]){
            continue;
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:filepath]){
            //文件删除事件
            //被监控的文件夹目录下面，有文件被删除
            goto fileDeletedEvent;
        }
        
        if(flagg & kFSEventStreamEventFlagItemCreated){
            //文件创建事件
            goto fileCreatedEvent;
        }
        
        if(flagg & kFSEventStreamEventFlagItemIsFile){
            //文件操作相关的任何事件，只要这个文件是一个常规的文件，而不是目录
            goto fileCreatedEvent;
        }
        
    fileCreatedEvent:
        //文件创建事件
        if(ff &&
           [ff isKindOfClass:[TBFileMonitor class]] &&
           ff.fileMonitorDelegate &&
           [ff.fileMonitorDelegate respondsToSelector:@selector(itemCreatedAtPath:)]){
            
            [ff.fileMonitorDelegate itemCreatedAtPath:filepath];
        }
        continue;
        
    fileDeletedEvent:
        //文件删除事件
        if(ff &&
           [ff isKindOfClass:[TBFileMonitor class]] &&
           ff.fileMonitorDelegate &&
           [ff.fileMonitorDelegate respondsToSelector:@selector(itemDeletedWithOriginItemPath:)]){
            
            [ff.fileMonitorDelegate itemDeletedWithOriginItemPath:filepath];
        }
        continue;
    }
}

#pragma mark - filter file
+(BOOL)isSystemFileEvent:(nonnull NSString *)fileName{
    
    if(fileName==nil ||
       fileName==NULL ||
       ![fileName isKindOfClass:[NSString class]]){
        return YES;
    }
    
    if([fileName hasPrefix:@"."]){
        return YES;
    }
    
    return NO;
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

-(FSEventStreamRef)fsEventStream{
    if(_fsEventStream==NULL ||
       _fsEventStream==nil){
        
        if(self.fsEventMonitorPathDirectory!=nil &&
           self.fsEventMonitorPathDirectory!=NULL &&
           self.fsEventMonitorPathDirectory.length>0){
            
            NSArray *paths=@[self.fsEventMonitorPathDirectory];
            FSEventStreamContext context;
            context.info=(__bridge void * _Nullable)(self);
            context.version=0;
            context.retain=NULL;
            context.release=NULL;
            context.copyDescription=NULL;
            _fsEventStream=FSEventStreamCreate(kCFAllocatorDefault, &fsevents_callback, &context, (__bridge CFArrayRef _Nonnull)(paths), kFSEventStreamEventIdSinceNow, FSEventLatencyTime,kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagMarkSelf | kFSEventStreamCreateFlagUseCFTypes);
        }
    }
    
    return _fsEventStream;
}

@end
