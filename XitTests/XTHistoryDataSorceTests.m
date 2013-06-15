#import "XTTest.h"
#import "XTRepository.h"
#import "XTRepository+Commands.h"
#import "XTHistoryDataSource.h"
#import "XTHistoryItem.h"

@interface XTHistoryDataSorceTests : XTTest

@end

@implementation XTHistoryDataSorceTests

- (void)testRootCommitsGraph
{
  NSInteger nCommits = 15;
  NSFileManager *defaultManager = [NSFileManager defaultManager];

  for (int n = 0; n < nCommits; n++) {
    NSString *rn = [NSString stringWithFormat:@"refs/heads/root_%d", n];
    if ((n % 5) == 0) {
      NSData *data =
          [repository executeGitWithArgs:@[ @"symbolic-ref", @"HEAD", rn ]
                                   error:nil];
      if (data == nil) {
        STFail(@"'%@' error", rn);
      }
      data = [repository executeGitWithArgs:@[ @"rm", @"--cached", @"-r", @"." ]
                                      error:nil];
      if (data == nil) {
        STFail(@"'%@' error", rn);
      }
      data =
          [repository executeGitWithArgs:@[ @"clean", @"-f", @"-d" ] error:nil];
      if (data == nil) {
        STFail(@"'%@' error", rn);
      }
    }

    NSString *testFile = [repoPath stringByAppendingPathComponent:
        [NSString stringWithFormat:@"file%d.txt", n]];
    NSString *content = [NSString stringWithFormat:@"some text %d", n];
    [content writeToFile:testFile
              atomically:YES
                encoding:NSASCIIStringEncoding
                   error:nil];

    if (![defaultManager fileExistsAtPath:testFile]) {
      STFail(@"testFile NOT Found!!");
    }
    if (![repository addFile:[testFile lastPathComponent]]) {
      STFail(@"add file '%@'", testFile);
    }
    if (![repository commitWithMessage:
                [NSString stringWithFormat:@"new file%d.txt", n]]) {
      STFail(@"Commit with mesage 'new file%d.txt", n);
    }
  }

  XTHistoryDataSource *hds = [[XTHistoryDataSource alloc] init];
  [hds setRepo:repository];
  [self waitForRepoQueue];

  NSArray *items = hds.items;

  [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    XTHistoryItem *item = (XTHistoryItem *)obj;

    if (idx == (items.count - 1)) {
      STAssertEquals(item.lineInfo.numColumns, 0UL,
                     @"item %d", idx);
    } else {
      STAssertEquals(item.lineInfo.numColumns, 1UL,
                     @"item %d", idx);
    }
  }];
}

- (void)testXTHistoryDataSource
{
  NSInteger nCommits = 60;
  NSFileManager *defaultManager = [NSFileManager defaultManager];

  for (int n = 0; n < nCommits; n++) {
    NSString *bn = [NSString stringWithFormat:@"branch_%d", n];
    if ((n % 10) == 0) {
      [repository checkout:@"master" error:NULL];
      if (![repository createBranch:bn]) {
        STFail(@"Create Branch");
      }
    }

    NSString *testFile =
        [NSString stringWithFormat:@"%@/file%d.txt", repoPath, n];
    NSString *txt = [NSString stringWithFormat:@"some text %d", n];
    [txt writeToFile:testFile
          atomically:YES
            encoding:NSASCIIStringEncoding
               error:nil];

    if (![defaultManager fileExistsAtPath:testFile]) {
      STFail(@"testFile NOT Found!!");
    }
    if (![repository addFile:[testFile lastPathComponent]]) {
      STFail(@"add file '%@'", testFile);
    }
    if (![repository commitWithMessage:
                [NSString stringWithFormat:@"new %@", testFile]]) {
      STFail(@"Commit with mesage 'new %@'", testFile);
    }
  }

  XTHistoryDataSource *hds = [[XTHistoryDataSource alloc] init];
  [hds setRepo:repository];
  [self waitForRepoQueue];

  NSUInteger nc = [hds numberOfRowsInTableView:nil];
  STAssertTrue((nc == (nCommits + 1)), @"found %d commits", nc);
}

@end
