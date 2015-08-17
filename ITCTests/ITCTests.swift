//
//  ITCTests.swift
//  ITCTests
//
//  Created by Matthias Bartelmeß on 16/08/15.
//  Copyright © 2015 fourplusone. All rights reserved.
//

import XCTest
import itc

class ITCTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testStamp() {
        var a = Stamp()
        print(a.description)
        XCTAssert(a.description == "(1, 0)")
    }
    
    func testEvent() {
        var a = Stamp()
        a.event()
        XCTAssert(a.description == "(1, 1)")
    }
    
    func testSimple() {
        var a = Stamp(); // a
        var b:Stamp;
        var c:Stamp;
        
        b = a.fork(); // b
        
        a.event(); // c
        b.event(); // c
        
        c = a.fork(); // d
        b.event(); // d
        
        a.event(); // e
        b.join(c); // e
        
        
        c = b.fork(); // f
        
        a.join(b); // g
        
        a.event(); // h
        
        XCTAssertEqual(a.description, "((1, 0), 2)")
    }
}
