import XCTest
@testable import Xit

let message = "testing"
let tagName = "testTag"

class XTTagTest: XTTest
{
  func testAnnotatedTag()
  {
    try! repository.executeGit(withArgs: ["tag", "-a", tagName, "-m", message],
                               writes: true)
    checkTag(hasMessage: true)
  }
  
  func testLightweightTag()
  {
    try! repository.executeGit(withArgs: ["tag", tagName],
                               writes: true)
    checkTag(hasMessage: false)
  }
  
  // The message comes through with an extra newline at the end
  func trimmedMessage(tag: XTTag) -> String
  {
    return (tag.message! as NSString)
           .trimmingCharacters(in: CharacterSet.newlines)
  }
  
  func checkTag(hasMessage: Bool)
  {
    guard let tag = XTTag(repository: repository, name:tagName)
    else {
      XCTFail("tag not found")
      return
    }
    XCTAssertNotNil(tag.targetSHA)
    if hasMessage {
      XCTAssertEqual(trimmedMessage(tag: tag), message)
    }
    
    guard let fullTag = XTTag(repository: repository,
                              name: "refs/tags/" + tagName)
    else {
      XCTFail("tag not found by full name")
      return
    }
    XCTAssertNotNil(fullTag.targetSHA)
    if hasMessage {
      XCTAssertEqual(trimmedMessage(tag: fullTag), message)
    }
  }
}
