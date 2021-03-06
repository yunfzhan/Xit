#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, XTRefType) {
  XTRefTypeBranch,
  XTRefTypeActiveBranch,
  XTRefTypeRemoteBranch,
  XTRefTypeTag,
  XTRefTypeRemote,
  XTRefTypeUnknown
};

typedef NS_ENUM(NSInteger, XTGroupIndex) {
  XTGroupIndexWorkspace,
  XTGroupIndexBranches,
  XTGroupIndexRemotes,
  XTGroupIndexTags,
  XTGroupIndexStashes,
  XTGroupIndexSubmodules,
};

typedef NS_ENUM(NSUInteger, XTError) {
  XTErrorWriteLock = 1,
  XTErrorUnexpectedObject,
};

typedef NS_ENUM(NSUInteger, XTWhitespace) {
  XTWhitespaceShowAll,
  XTWhitespaceIgnoreEOL,
  XTWhitespaceIgnoreAll,
};

extern NSString *XTErrorDomainXit, *XTErrorDomainGit;

/// Fake value for seleting staging view.
extern NSString * const XTStagingSHA;

/// Some change has been detected in the repository.
extern NSString * const XTRepositoryChangedNotification;

/// The repository's index has changed.
extern NSString * const XTRepositoryIndexChangedNotification;

/// The repository's refs have changed.
extern NSString * const XTRepositoryRefsChangedNotification;

/// The head reference (current branch) has changed.
extern NSString * const XTRepositoryHeadChangedNotification;

/// A file in the workspace has changed.
extern NSString * const XTRepositoryWorkspaceChangedNotification;

/// There is a new selection to be displayed.
extern NSString * const XTSelectedModelChangedNotification;

/// The selection has been clicked again. Make sure it is visible.
extern NSString * const XTReselectModelNotification;

/// TeamCity build status has been downloaded/refreshed.
extern NSString * const XTTeamCityStatusChangedNotification;
