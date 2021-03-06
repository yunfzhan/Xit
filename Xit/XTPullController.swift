import Cocoa

class XTPullController: XTFetchController
{
  override func start() {
    defer {
      windowController?.operationEnded(self)
    }
    guard let repository = repository,
          let branchName = repository.currentBranch,
          let branch = XTLocalBranch(repository: repository,
                                     name: branchName)
    else {
      NSLog("Can't get current branch")
      return
    }
    guard let remoteBranch = branch.trackingBranch,
          let remote = XTRemote(name: remoteBranch.remoteName,
                                repository: repository)
    else {
      NSLog("Can't pull - no tracking branch")
      return
    }
    
    tryRepoOperation(successStatus: "Pull complete",
                     failureStatus: "Pull failed") {
      try repository.pull(branch: branch,
                          remote: remote,
                          downloadTags: true,
                          pruneBranches: true,
                          passwordBlock: self.getPassword,
                          progressBlock: self.shouldStop)
      NotificationCenter.default.post(
          name: NSNotification.Name.XTRepositoryRefsChanged, object: repository)
      self.ended()
    }
  }

}
