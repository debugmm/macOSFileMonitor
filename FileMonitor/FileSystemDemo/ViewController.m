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
        
        NSString *originPath=[NSString stringWithFormat:@"origin path:%@",[weakOP.URL.absoluteString stringByRemovingPercentEncoding]];
        [self updateTextViewString:originPath];
    }];
}

- (IBAction)unMonitorFile:(NSButton *)sender {
    
    [self.fm removeMonitor];
    self.fm=nil;
}

- (IBAction)resumeMonitor:(NSButton *)sender {
    
    if(self.fm){
        [NSFileCoordinator addFilePresenter:self.fm];
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

#pragma mark - update textview string
-(void)updateTextViewString:(nonnull NSString *)string{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string=[NSString stringWithFormat:@"%@\n%@",self.textView.string,string];
    });
}

@end
