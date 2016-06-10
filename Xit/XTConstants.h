#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, XTRefType) {
  XTRefTypeBranch,
  XTRefTypeActiveBranch,
  XTRefTypeRemoteBranch,
  XTRefTypeTag,
  XTRefTypeRemote,
  XTRefTypeUnknown
};

typedef enum {
  XTWorkspaceGroupIndex,
  XTBranchesGroupIndex,
  XTRemotesGroupIndex,
  XTTagsGroupIndex,
  XTStashesGroupIndex,
  XTSubmodulesGroupIndex,
} XTSideBarRootItems;

typedef NS_ENUM(NSUInteger, XTError) {
  XTErrorWriteLock = 1
};

extern NSString *XTErrorDomainXit, *XTErrorDomainGit;

/// Fake value for seleting staging view.
extern NSString * const XTStagingSHA;

/// The repository's index has changed.
extern NSString * const XTRepositoryIndexChangedNotification;
