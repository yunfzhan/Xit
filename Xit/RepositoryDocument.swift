import Cocoa

class RepositoryDocument: NSDocument
{
  let repoURL: URL
  let repository: XTRepository

  public init(url: URL, repository: XTRepository)
  {
    self.repoURL = url
    self.repository = repository
    
    super.init()
  }

  convenience init(contentsOf url: URL,
                   ofType typeName: String) throws
  {
    guard let repo = XTRepository(url: url)
    else {
      throw NSError(domain: NSCocoaErrorDomain,
                    code: NSFileNoSuchFileError,
                    userInfo: nil)
    }
    
    self.init(url: url, repository: repo)
  }
  
  public override func makeWindowControllers()
  {
    let controller = XTWindowController(windowNibName: "XTDocument")
    
    addWindowController(controller)
  }
  
  override func read(from url: URL, ofType typeName: String) throws
  {
    let gitURL = url.appendingPathComponent(".git", isDirectory: true)
    
    if !FileManager.default.fileExists(atPath: gitURL.path) {
      throw NSError(domain: NSCocoaErrorDomain,
                    code: NSFileReadUnknownError,
                    userInfo: [NSLocalizedFailureReasonErrorKey:
                               "The folder does not contain a Git repository"])
    }
  }
  
  override func canClose(withDelegate delegate: Any,
                         shouldClose shouldCloseSelector: Selector?,
                         contextInfo: UnsafeMutableRawPointer?)
  {
    repository.shutDown()
    WaitForQueue(repository.queue)
    super.canClose(withDelegate: delegate,
                   shouldClose: shouldCloseSelector,
                   contextInfo: contextInfo)
  }
  
  override func updateChangeCount(_ change: NSDocumentChangeType)
  {
    // Do nothing. There is no need for an "unsaved" state.
  }
}
