//
//  main.swift
//  itc-test
//
//  Created by Matthias Bartelmeß on 16/08/15.
//  Copyright © 2015 fourplusone. All rights reserved.
//

import Foundation

var a = Stamp(); // a
var b:Stamp;
var c:Stamp;

b = a.fork(); // b
print(a)

a.event(); // c
b.event(); // c
print(a)

c = a.fork(); // d
b.event(); // d
print(a)


print(a.e)
a.event(); // e
print(a.e);
b.join(c); // e


c = b.fork(); // f

a.join(b); // g

a.event(); // h

print(a)
print(c)


