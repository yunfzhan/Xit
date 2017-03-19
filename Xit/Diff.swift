import Foundation


class GitDiff
{
  let diff: OpaquePointer
  
  init(diff: OpaquePointer)
  {
    self.diff = diff
  }
  
  deinit
  {
    git_diff_free(diff)
  }
  
  var deltaCount: Int { return git_diff_num_deltas(diff) }
  
  func delta(at index: Int) -> git_diff_delta?
  {
    let deltaPtr = git_diff_get_delta(diff, index)
    
    return deltaPtr?.pointee
  }
}

class GitBlob
{
  let blob: OpaquePointer
  
  init(blob: OpaquePointer)
  {
    self.blob = blob
  }
  
  init?(oid: GitOID, repository: XTRepository)
  {
    let objectPtr = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
    
    guard git_object_lookup(objectPtr, repository.gtRepo.git_repository(),
                            oid.unsafeOID(), GIT_OBJ_BLOB) == 0,
          let object = objectPtr.pointee
    else { return nil }
    
    blob = object
  }
  
  var size: Int { return Int(git_blob_rawsize(blob)) }
}

extension Data
{
  init?(blob: GitBlob)
  {
    guard let content = git_blob_rawcontent(blob.blob)
    else { return nil }
    
    self.init(bytes: content, count: blob.size)
  }
}

class GitDiffDelta
{
  let diff: git_diff_delta
  
  init(from fromBlob: GitBlob, forPath fromPath: String,
       to toBlob: GitBlob, forPath toPath: String)
  {
    
  }
}

class GitPatch
{
  static let encodings: [String.Encoding] =
    [.utf8, .isoLatin1, .isoLatin2, .windowsCP1252, .macOSRoman]
  
  let patch: OpaquePointer
  
  var hunkCount: Int { return git_patch_num_hunks(patch) }
  
  init(patch: OpaquePointer)
  {
    self.patch = patch
  }
  
  init?(old: Data, new: Data)
  {
    let patchPtr = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
    let result = old.withUnsafeBytes({
      (oldUnsafe: UnsafePointer<Int8>) -> Int in
      return new.withUnsafeBytes({
        (newUnsafe: UnsafePointer<Int8>) -> Int in
        let oldRaw = UnsafeRawPointer(oldUnsafe)
        let optionsMutable = UnsafeMutablePointer<git_diff_options>
                             .allocate(capacity: 1)
        let options = UnsafePointer(optionsMutable)
        
        git_diff_init_options(optionsMutable, UInt32(GIT_DIFF_OPTIONS_VERSION))
        return Int(git_patch_from_buffers(patchPtr,
                                          oldRaw, old.count, nil,
                                          newUnsafe, new.count, nil,
                                          options))
      })
    })
    
    guard result == 0,
          let patch = patchPtr.pointee
    else { return nil }
    
    self.patch = patch
  }
  
  deinit
  {
    git_patch_free(patch)
  }
}

extension String
{
  enum LineEndingStyle: String
  {
    case crlf
    case lf
    case unknown
    
    var string: String
    {
      switch self
      {
        case .crlf: return "\r\n"
        case .lf:   return "\n"
        case .unknown: return "\n"
      }
    }
  }
  
  var lineEndingStyle: LineEndingStyle
  {
    if range(of: "\r\n") != nil {
      return .crlf
    }
    if range(of: "\n") != nil {
      return .lf
    }
    return .unknown
  }

  static func from(data: Data, possibleEncodings: [String.Encoding])
    -> (String, String.Encoding)?
  {
    for encoding in possibleEncodings {
      if let string = String(data: data, encoding: encoding) {
        return (string, encoding)
      }
    }
    return nil
  }
}


class GitPatchHunk
{
  let patch: OpaquePointer
  let index: Int
  let hunk: git_diff_hunk
  
  struct LineError: Error {}
  
  init?(patch: OpaquePointer, index: Int)
  {
    let hunkPtr = UnsafeMutablePointer<UnsafePointer<git_diff_hunk>?>
                  .allocate(capacity: 1)
  
    guard git_patch_get_hunk(hunkPtr, nil, patch, index) == 0,
          let hunk = hunkPtr.pointee?.pointee
    else { return nil }
    
    self.patch = patch
    self.index = index
    self.hunk = hunk
  }
  
  var oldLineStart: Int { return Int(hunk.old_start) }
  var oldLineCount: Int { return Int(hunk.old_lines) }
  var newLineStart: Int { return Int(hunk.new_start) }
  var newLineCount: Int { return Int(hunk.new_lines) }
  
  func applied(to text: String) -> String?
  {
    var lines = text.components(separatedBy: .newlines)
    guard (oldLineStart + oldLineCount) < lines.count
    else { return nil }
    
    do {
      let lineRange = 0..<newLineCount
      let hunkLines = try lineRange.map {
        (index: Int) -> GitPatchHunkLine in
        guard let line = GitPatchHunkLine(patch: patch, hunkIndex: index,
                                          hunkLine: index)
        else { throw LineError() }
        
        return line
      }
      var oldLines = [String]()
      var newLines = [String]()
      
      for line in hunkLines {
        let content = line.generateContent()
        
        switch line.origin {
          case .context:
            oldLines.append(content)
            newLines.append(content)
          case .addition:
            newLines.append(content)
          case .deletion:
            oldLines.append(content)
        }
      }
      
      let oldLineStart = Int(hunk.old_start) - 1
      let oldLineCount = Int(hunk.old_lines)
      let replaceRange = oldLineStart..<(oldLineStart+oldLineCount)
      
      if oldLines != Array(lines[replaceRange]) {
        // Patch doesn't match
        return nil
      }
      lines.replaceSubrange(replaceRange, with: newLines)
      
      return lines.joined(separator: text.lineEndingStyle.string)
    }
    catch {
      return nil
    }
  }
}


class GitPatchHunkLine
{
  let line: git_diff_line
  
  enum Origin
  {
    case context
    case addition
    case deletion
    
    init(_ origin: git_diff_line_t)
    {
      switch origin {
        case GIT_DIFF_LINE_CONTEXT:
          self = .context
        case GIT_DIFF_LINE_ADDITION:
          self = .addition
        case GIT_DIFF_LINE_DELETION:
          self = .deletion
        default:
          self = .context
      }
    }
  }
  
  init?(patch: OpaquePointer, hunkIndex: Int, hunkLine: Int)
  {
    let linePtr = UnsafeMutablePointer<UnsafePointer<git_diff_line>?>
                  .allocate(capacity: 1)
    
    guard git_patch_get_line_in_hunk(linePtr, patch, hunkIndex, hunkLine) == 0,
          let line = linePtr.pointee?.pointee
    else { return nil }
    
    self.line = line
  }
  
  var origin: Origin { return Origin(git_diff_line_t(UInt32(line.origin))) }
  var oldLine: Int { return Int(line.old_lineno) }
  var newLine: Int { return Int(line.new_lineno) }
  var lineCount: Int { return Int(line.num_lines) }
  lazy var content: String = self.generateContent()
  
  func generateContent() -> String
  {
    guard let raw = UnsafeMutableRawPointer(
        mutating: UnsafeRawPointer(line.content))
    else { return "" }
    let data = Data(bytesNoCopy: raw, count: line.content_len,
                    deallocator: .none)
    
    for encoding in GitPatch.encodings {
      if let string = String(data: data, encoding: encoding) {
        return string
      }
    }
    return ""
  }
}
