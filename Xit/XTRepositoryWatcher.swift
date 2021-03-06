import Foundation

let XTAddedRefsKey = "addedRefs"
let XTDeletedRefsKey = "deletedRefs"
let XTChangedRefsKey = "changedRefs"

// Remove inheritance when XTRepository is converted to Swift
@objc class XTRepositoryWatcher: NSObject
{
  unowned let repository: XTRepository

  // stream must be var because we have to reference self to initialize it.
  var stream: FileEventStream! = nil
  var packedRefsWatcher: XTFileMonitor?
  var lastIndexChange = Date()
  {
    didSet
    {
      NotificationCenter.default.post(
          name: NSNotification.Name.XTRepositoryIndexChanged, object: repository)
    }
  }
  var refsCache = [String: GTOID]()

  init?(repository: XTRepository)
  {
    self.repository = repository
    super.init()
    
    let objectsPath = repository.gitDirectoryURL.path
                      .appending(pathComponent: "objects")
    guard let stream = FileEventStream(path: repository.gitDirectoryURL.path,
                                       excludePaths: [objectsPath],
                                       queue: repository.queue,
                                       callback: {
       [weak self] (paths) in
       self?.observeEvents(paths)
    })
    else { return nil }
  
    self.stream = stream
    makePackedRefsWatcher()
  }
  
  func stop()
  {
    stream.stop()
    packedRefsWatcher = nil
  }
  
  func makePackedRefsWatcher()
  {
    let path = repository.gitDirectoryURL.path
    
    self.packedRefsWatcher =
        XTFileMonitor(path: path.appending(pathComponent: "packed-refs"))
    self.packedRefsWatcher?.notifyBlock = {
      [weak self] (_, _) in
      self?.checkRefs()
    }
  }
  
  func index(refs: [String]) -> [String: GTOID]
  {
    var result = [String: GTOID]()
    
    for ref in refs {
      guard let oid = repository.sha(forRef: ref).flatMap({ GTOID(sha: $0) })
      else { continue }
      
      result[ref] = oid
    }
    return result
  }
  
  func checkIndex()
  {
    let gitPath = repository.gitDirectoryURL.path
    let indexPath = gitPath.appending(pathComponent: "index")
    guard let indexAttributes = try? FileManager.default
                                     .attributesOfItem(atPath: indexPath),
          let newMod = indexAttributes[FileAttributeKey.modificationDate]
                       as? Date
    else {
      lastIndexChange = Date.distantPast
      return
    }
    
    if lastIndexChange.compare(newMod) != .orderedSame {
      lastIndexChange = newMod
    }
  }
  
  func paths(_ paths: [String], includeSubpaths subpaths: [String]) -> Bool
  {
    for path in paths {
      for subpath in subpaths {
        if path.hasSuffix(subpath) ||
           path.deletingLastPathComponent.hasSuffix(subpath) {
          return true
        }
      }
    }
    return false
  }
  
  func checkRefs(_ changedPaths: [String])
  {
    if packedRefsWatcher == nil,
       changedPaths.index(of: repository.gitDirectoryURL.path) != nil {
      makePackedRefsWatcher()
    }
    
    if paths(changedPaths, includeSubpaths: ["refs/heads", "refs/remotes"]) {
      checkRefs()
    }
  }
  
  func checkHead(_ changedPaths: [String])
  {
    if paths(changedPaths, includeSubpaths: ["HEAD"]) {
      NotificationCenter.default.post(name: .XTRepositoryHeadChanged,
                                      object: repository)
    }
  }
  
  func checkRefs()
  {
    let newRefCache = index(refs: repository.allRefs())
    let newKeys = Set(newRefCache.keys)
    let oldKeys = Set(refsCache.keys)
    let addedRefs = newKeys.subtracting(oldKeys)
    let deletedRefs = oldKeys.subtracting(newKeys)
    let changedRefs = newKeys.subtracting(addedRefs).filter {
      (ref) -> Bool in
      guard let oldOID = refsCache[ref],
            let newSHA = self.repository.sha(forRef: ref),
            let newOID =  GTOID(sha: newSHA)
      else { return false }
      
      return oldOID != newOID
    }
    
    var refChanges = [String: Set<String>]()
    
    if !addedRefs.isEmpty {
      refChanges[XTAddedRefsKey] = addedRefs
    }
    if !deletedRefs.isEmpty {
      refChanges[XTDeletedRefsKey] = deletedRefs
    }
    if !changedRefs.isEmpty {
      refChanges[XTChangedRefsKey] = Set(changedRefs)
    }
    
    if !refChanges.isEmpty {
      repository.rebuildRefsIndex()
      NotificationCenter.default.post(name: .XTRepositoryRefsChanged,
                                      object: repository)
      repository.refsChanged()
    }
    
    refsCache = newRefCache
  }
  
  func checkLogs(_ changedPaths: [String])
  {
    if paths(changedPaths, includeSubpaths: ["logs/refs"]) {
      NotificationCenter.default.post(name: .XTRepositoryRefLogChanged,
                                      object: repository)
    }
  }
  
  func observeEvents(_ paths: [String])
  {
    // FSEvents includes trailing slashes, but some other APIs don't.
    let standardizedPaths = paths.map({ ($0 as NSString).standardizingPath })
  
    checkIndex()
    checkHead(standardizedPaths)
    checkRefs(standardizedPaths)
    checkLogs(standardizedPaths)
    
    NotificationCenter.default.post(
        name: NSNotification.Name.XTRepositoryChanged, object: repository)
  }
}
