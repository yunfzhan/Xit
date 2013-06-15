#import "XTTest.h"
#import "XTRepository.h"
#import "XTRepository+Commands.h"

@implementation XTTest

- (void)setUp
{
  [super setUp];

  repoPath = [NSString stringWithFormat:@"%@testrepo", NSTemporaryDirectory()];
  repository = [self createRepo:repoPath];

  [self addInitialRepoContent];

  NSLog(@"setUp ok");
}

- (void)tearDown
{
  [self waitForRepoQueue];

  NSFileManager *defaultManager = [NSFileManager defaultManager];
  [defaultManager removeItemAtPath:repoPath error:nil];
  [defaultManager removeItemAtPath:remoteRepoPath error:nil];

  if ([defaultManager fileExistsAtPath:repoPath]) {
    STFail(@"tearDown %@ FAIL!!", repoPath);
  }

  if ([defaultManager fileExistsAtPath:remoteRepoPath]) {
    STFail(@"tearDown %@ FAIL!!", remoteRepoPath);
  }

  NSLog(@"tearDown ok");

  [super tearDown];
}

- (void)makeRemoteRepo
{
  remoteRepoPath =
      [NSString stringWithFormat:@"%@remotetestrepo", NSTemporaryDirectory()];
  remoteRepoPath = [remoteRepoPath stringByResolvingSymlinksInPath];
  remoteRepository = [self createRepo:remoteRepoPath];
}

- (void)addInitialRepoContent
{
  file1RelativePath = @"file1.txt";
  file1FullPath = [repoPath stringByAppendingPathComponent:file1RelativePath];
  STAssertTrue([self commitNewTextFile:file1RelativePath content:@"some text"],
               nil);
}

- (BOOL)commitNewTextFile:(NSString *)name content:(NSString *)content
{
  NSString *filePath = [repoPath stringByAppendingPathComponent:name];

  [content writeToFile:filePath
            atomically:YES
              encoding:NSASCIIStringEncoding
                 error:nil];

  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    return NO;
  if (![repository addFile:name])
    return NO;
  if (![repository
          commitWithMessage:[NSString stringWithFormat:@"new %@", name]])
    return NO;

  return YES;
}

- (XTRepository *)createRepo:(NSString *)path
{
  NSLog(@"[createRepo] repoName=%@", path);
  NSFileManager *fileManager = [NSFileManager defaultManager];

  if ([fileManager fileExistsAtPath:path]) {
    [fileManager removeItemAtPath:path error:nil];
  }
  [fileManager createDirectoryAtPath:path
         withIntermediateDirectories:YES
                          attributes:nil
                               error:nil];

  NSURL *repoURL = [NSURL URLWithString:
          [NSString stringWithFormat:@"file://localhost%@", path]];

  XTRepository *repo = [[XTRepository alloc] initWithURL:repoURL];

  if (![repo initializeRepository]) {
    STFail(@"initializeRepository '%@' FAIL!!", path);
  }

  if (![fileManager
          fileExistsAtPath:[NSString stringWithFormat:@"%@/.git", path]]) {
    STFail(@"%@/.git NOT Found!!", path);
  }

  return repo;
}

- (void)waitForQueue:(dispatch_queue_t)queue
{
  // Some queued tasks need to also perform tasks on the main thread, so
  // simply waiting on the queue could cause a deadlock.
  const CFRunLoopRef loop = CFRunLoopGetCurrent();
  __block BOOL keepLooping = YES;

  // Loop because something else might quit the run loop.
  do {
    CFRunLoopPerformBlock(loop, kCFRunLoopCommonModes, ^{
      dispatch_async(queue, ^{
        CFRunLoopStop(loop);
        keepLooping = NO;
      });
    });
    CFRunLoopRun();
  } while (keepLooping);
}

- (void)waitForRepoQueue
{
  [self waitForQueue:repository.queue];
}

- (BOOL)writeTextToFile1:(NSString *)text
{
  NSError *error;

  [text writeToFile:file1FullPath
         atomically:YES
           encoding:NSASCIIStringEncoding
              error:&error];
  return error == nil;
}

@end
