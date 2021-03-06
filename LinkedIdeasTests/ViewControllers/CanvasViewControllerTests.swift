//
//  CanvasViewControllerTests.swift
//  LinkedIdeas
//
//  Created by Felipe Espinoza Castillo on 15/09/2016.
//  Copyright © 2016 Felipe Espinoza Dev. All rights reserved.
//

import XCTest
import LinkedIdeas_Shared
@testable import LinkedIdeas

extension CanvasViewController {
  func fullClick(event: NSEvent) {
    self.mouseDown(with: event)
    self.mouseDragged(with: event)
    self.mouseUp(with: event)
  }

  func fullDrag(from fromPoint: CGPoint, to toPoint: CGPoint, shift: Bool = false) {
    self.mouseDown(with: EventHelpers.createMouseEvent(clickCount: 1, location: fromPoint, shift: shift))
    // TODO: try to make a range between the 2 points

    self.mouseUp(with: EventHelpers.createMouseEvent(clickCount: 1, location: toPoint, shift: shift))
  }
}

struct EventHelpers {
  // this is used because of flipping the CanvasView for working with iOS
  static func invertY(_ point: CGPoint) -> CGPoint {
    return CGPoint(x: point.x, y: -point.y)
  }

  static func createMouseEvent(clickCount: Int, location: CGPoint, shift: Bool = false) -> NSEvent {
    var flags: NSEvent.ModifierFlags = NSEvent.ModifierFlags.function

    if shift {
      flags = NSEvent.ModifierFlags.shift
    }

    return NSEvent.mouseEvent(
      with: .leftMouseDown,
      location: invertY(location),
      modifierFlags: flags,
      timestamp: 2,
      windowNumber: 0,
      context: nil,
      eventNumber: 0,
      clickCount: clickCount,
      pressure: 1.0
    )!
  }

  static func createKeyboardEvent(keyCode: UInt16, shift: Bool = false) -> NSEvent {
    var flags: NSEvent.ModifierFlags = NSEvent.ModifierFlags.function

    if shift {
      flags = NSEvent.ModifierFlags.shift
    }

    return NSEvent.keyEvent(
      with: .keyDown,
      location: CGPoint.zero,
      modifierFlags: flags,
      timestamp: 2,
      windowNumber: 0,
      context: nil,
      characters: "",
      charactersIgnoringModifiers: "",
      isARepeat: false,
      keyCode: keyCode
    )!
  }
}

class CanvasViewControllerTests: XCTestCase {
  func createMouseEvent(clickCount: Int, location: CGPoint, shift: Bool = false) -> NSEvent {
    return EventHelpers.createMouseEvent(clickCount: clickCount, location: location, shift: shift)
  }

  func createKeyboardEvent(keyCode: UInt16, shift: Bool = false) -> NSEvent {
    return EventHelpers.createKeyboardEvent(keyCode: keyCode, shift: shift)
  }

  var canvasViewController: CanvasViewController!
  var canvasView: CanvasView!
  var scrollView: NSScrollView!
  var document: TestLinkedIdeasDocument!

  override func setUp() {
    super.setUp()

    canvasViewController = CanvasViewController()
    canvasView = CanvasView()
    scrollView = NSScrollView()
    canvasViewController.scrollView = scrollView
    canvasViewController.canvasView = canvasView
    document = TestLinkedIdeasDocument()
    canvasViewController.document = document
  }
}

// MARK: - CanvasViewController: Basic Behavior

extension CanvasViewControllerTests {
  func testClickedConceptsAtPointWhenIntercepsAConcept() {
    let clickedPoint = CGPoint(x: 205, y: 305)

    let concepts = [
      Concept(stringValue: "Foo #0", centerPoint: CGPoint(x: 210, y: 310)),
      Concept(stringValue: "Foo #1", centerPoint: CGPoint(x: 210, y: 110)),
      Concept(stringValue: "Foo #2", centerPoint: CGPoint(x: 200, y: 300)),
    ]
    document.concepts = concepts

    let clickedConcepts = canvasViewController.clickedConcepts(atPoint: clickedPoint)

    XCTAssertEqual(clickedConcepts?.count, 2)
    XCTAssertEqual(clickedConcepts?.contains(concepts[0]), true)
    XCTAssertEqual(clickedConcepts?.contains(concepts[2]), true)
  }

  func testClickedConceptsAtPointWithNoResults() {
    let clickedPoint = CGPoint(x: 1200, y: 1300)

    let concepts = [
      Concept(stringValue: "Foo #0", centerPoint: CGPoint(x: 210, y: 310)),
      Concept(stringValue: "Foo #1", centerPoint: CGPoint(x: 210, y: 110)),
      Concept(stringValue: "Foo #2", centerPoint: CGPoint(x: 200, y: 300)),
      ]
    document.concepts = concepts

    let clickedConcepts = canvasViewController.clickedConcepts(atPoint: clickedPoint)

    XCTAssertTrue(clickedConcepts == nil)
  }
}

// MARK: - CanvasViewControllers: TextView Delegate Tests

extension CanvasViewControllerTests {
  func testPressEnterKeyWhenEditingInTheTextView() {
    let conceptPoint = CGPoint.zero
    canvasViewController.currentState = .newConcept(point: conceptPoint)
    canvasViewController.stateManager.delegate = StateManagerTestDelegate()

    let textView = canvasViewController.textView
    canvasViewController.textStorage.setAttributedString(NSAttributedString(string: "New Concept"))

    _ = canvasViewController.textView(textView, doCommandBy: #selector(NSResponder.insertNewline(_:)))

    XCTAssertEqual(canvasViewController.currentState, .canvasWaiting)
  }
}

// MARK: - CanvasViewControllers: Transition Acction Tests

extension CanvasViewControllerTests {
  func testShowTextViewAt() {
    let clickedPoint = CGPoint(x: 400, y: 300)
    canvasViewController.showTextView(atPoint: clickedPoint)

    XCTAssertFalse(canvasViewController.textView.isHidden)
    XCTAssert(canvasViewController.textView.isEditable)
    XCTAssertEqual(canvasViewController.textView.frame.center, clickedPoint)
  }

  func testDismissTextView() {
    let textViewCenter = CGPoint(x: 400, y: 300)
    let textView = canvasViewController.textView
    textView.frame = CGRect(center: textViewCenter, size: CGSize(width: 60, height: 40))
    textView.textStorage?.setAttributedString(NSAttributedString(string: "Foo bar asdf"))
    textView.isHidden = false
    textView.isEditable = true

    canvasViewController.dismissTextView()

    XCTAssert(canvasViewController.textView.isHidden)
    XCTAssertFalse(canvasViewController.textView.isEditable)
    XCTAssertNotEqual(canvasViewController.textView.frame.center, textViewCenter)
    XCTAssertEqual(canvasViewController.textView.attributedString(), NSAttributedString(string: ""))
  }

  func testSaveConceptWithAppropriateData() {
    let document = TestLinkedIdeasDocument()
    canvasViewController.document = document

    let attributedString = NSAttributedString(string: "New Concept")
    let conceptCenterPoint = CGPoint(x: 300, y: 400)

    let concept = canvasViewController.saveConcept(
      text: attributedString,
      atPoint: conceptCenterPoint
    )

    XCTAssert(concept != nil)
    XCTAssertEqual(document.concepts.count, 1)
  }

  func testSaveConceptFailsWithBadData() {
    let document = TestLinkedIdeasDocument()
    canvasViewController.document = document

    let attributedString = NSAttributedString(string: "")
    let conceptCenterPoint = CGPoint(x: 300, y: 400)

    let concept = canvasViewController.saveConcept(
      text: attributedString,
      atPoint: conceptCenterPoint
    )

    XCTAssertFalse(concept != nil)
    XCTAssertEqual(document.concepts.count, 0)
  }
}
