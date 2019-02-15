# <center> macOS File Monitor </center>

## File Monitor for macOS

    这是一个macOS下，文件监控模块。
    
## Brief
    
    1. FileMonitorClasses，实现监控文件or文件夹功能模块
        
        1.1. TBFileMonitor类，实现了文件监控功能。文件的重命名和移动事件都可以被监控到。
        1.2. TBFileMonitorProtocol协议，通过实现此协议方法，任何类可以实现监听事件。
        
    2. 示例代码
    
        TBFileMonitor *fm=[TBFileMonitor monitorFileURL:weakOP.URL error:&er];
        fm.fileMonitorDelegate=self;
        
        #pragma mark - TBFileMonitorProtocol
        -(void)fileRenameToName:(NSString *)newName{
    
             NSString *str=[NSString stringWithFormat:@"new name:%@",[newName stringByRemovingPercentEncoding]]];
        }

        -(void)itemMoveToURL:(NSURL *)newURL{
    
            NSString *str=[NSString stringWithFormat:@"new path:%@",[newURL.absoluteString stringByRemovingPercentEncoding]];
        }

## Usage

    1. 可以通过文件path or 文件url生成针对“此文件”监控的fileMonitor object，并strong retain 它。
    2. 实现TBFileMonitorProtocol协议方法。
 
## Extensions

    后续会添加针对文件夹下，子文件相关事件处理。
    
## install
    