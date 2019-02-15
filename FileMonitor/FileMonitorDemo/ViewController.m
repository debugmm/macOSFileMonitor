//
//  ViewController.m
//  FileSystemDemo
//
//  Created by wujungao on 2019/1/15.
//  Copyright © 2019 wujungao. All rights reserved.
//

#import "ViewController.h"

#import "TBFileMonitor.h"

@interface ViewController()<TBFileMonitorProtocol>

- (IBAction)btnAction:(NSButton *)sender;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
- (IBAction)unMonitorFile:(NSButton *)sender;
- (IBAction)resumeMonitor:(NSButton *)sender;

@property(nonatomic,strong,nullable)TBFileMonitor *fm;

@property(nonatomic,copy)NSString *fpath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)btnAction:(NSButton *)sender {
    
    NSOpenPanel *op=[NSOpenPanel openPanel];
    op.canChooseFiles=YES;
    op.canChooseDirectories=YES;
    op.allowsMultipleSelection=NO;
    
    NSOpenPanel * __weak weakOP=op;
    [op beginWithCompletionHandler:^(NSModalResponse result) {
        
        NSError *er=nil;
        self.fm=[TBFileMonitor monitorFileURL:weakOP.URL error:&er];
        self.fm.fileMonitorDelegate=self;
        self.fpath=weakOP.URL.path;
        
        NSString *originPath=[NSString stringWithFormat:@"origin path:%@",[weakOP.URL.absoluteString stringByRemovingPercentEncoding]];
        [self updateTextViewString:originPath];
        
        [self.fm startMonitor];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *fppp=[self generateLogFileFullPath:[self basePathOfLogFile] fileName:[self fileNameGenerator]];
            
            [[NSFileManager defaultManager] createFileAtPath:fppp contents:[@"hhhxxxooo" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        });
    }];
}

- (IBAction)unMonitorFile:(NSButton *)sender {
    
//    [self.fm removeMonitor];
    self.fm=nil;
}

- (IBAction)resumeMonitor:(NSButton *)sender {
    
    if(self.fm){
        [self.fm startMonitor];
    }
}

#pragma mark -
-(void)fileRenameToName:(NSString *)newName{
    
    [self updateTextViewString:[NSString stringWithFormat:@"new name:%@",[newName stringByRemovingPercentEncoding]]];
}

-(void)itemMoveToURL:(NSURL *)newURL{
    
    NSString *str=[NSString stringWithFormat:@"new path:%@",[newURL.absoluteString stringByRemovingPercentEncoding]];
    [self updateTextViewString:str];
}

-(void)itemCreatedAtPath:(NSString *)newFullPath{
    
    NSString *str=[NSString stringWithFormat:@"created file:%@",newFullPath];
    [self updateTextViewString:str];
}

#pragma mark - update textview string
-(void)updateTextViewString:(nonnull NSString *)string{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string=[NSString stringWithFormat:@"%@\n%@",self.textView.string,string];
    });
}

#pragma mark -
-(nonnull NSString *)generateLogFileFullPath:(nonnull NSString *)basePath fileName:(nonnull NSString *)fileName{
    
    NSString *fp=[NSString stringWithFormat:@"%@/%@",basePath,fileName];
    
    return fp;
}


/**
 @brief 日志文件base path（basePath末尾未包含/，因此在生成文件完整路径时，应该添加/即：basePath/filename）
 （完整路径basePath/fileName）
 
 @return basePath is string type
 */
-(nonnull NSString *)basePathOfLogFile{
    
    NSString *basePath=self.fpath;//[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return basePath;
    /////
    NSString *bid=[NSBundle mainBundle].bundleIdentifier;
    basePath=[NSString stringWithFormat:@"%@/%@/%@",basePath,bid,@"exceptionlogs"];
    
    BOOL isDir=NO;
    NSFileManager *df=[NSFileManager defaultManager];
    NSError *er=nil;
    if([df fileExistsAtPath:basePath isDirectory:&isDir]){
        if(!isDir){
            //is not dir
            [df removeItemAtPath:basePath error:&er];
            [df createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&er];
        }
    }
    else{
        //not exsit
        [df createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&er];
    }
    
    if(er!=nil){
        //if error,do something
        basePath=@"";
    }
    
    return basePath;//格式：basepath，末尾没有反斜杠/
}

/**
 @brief log file文件名生成
 @return log file name 日志文件名
 @discussion 文件名生成规程：bundlename_dateString(yyy-mmm-dd-hh-mm-ss)_timeIntervalSinceReferenceDate String_exceptionLog.txt
 */
-(nonnull NSString *)fileNameGenerator{
    
    NSString *bdname=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *dateStr=[ViewController convertDateToYMDHMSString:[NSDate date]];
    NSString *timeIntStr=[NSString stringWithFormat:@"%f",[NSDate date].timeIntervalSinceReferenceDate];
    NSString *fileName=[NSString stringWithFormat:@"%@_%@_%@_exceptionLog.txt",bdname,dateStr,timeIntStr];
    
    return fileName;
}

#pragma mark -
+(nonnull NSString *)convertDateToYMDHMSString:(nonnull NSDate *)date{
    
    NSDateFormatter *format=[ViewController generateLocalDateFormatter];
    
    [format setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];//yyyy-MM-dd HH:mm:ss zzz
    
    NSString *dateString=[format stringFromDate:date];
    
    return dateString;
}

+(nonnull NSDateFormatter *)generateLocalDateFormatter{
    
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.locale=[NSLocale currentLocale];
    format.timeZone=[NSTimeZone localTimeZone];
    
    return format;
}

@end
