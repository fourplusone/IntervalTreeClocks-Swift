//
//  main.swift
//  itc-test
//
//  Created by Matthias Bartelmeß on 16/08/15.
//  Copyright © 2015 fourplusone. All rights reserved.
//

import Swift

public indirect enum Id : CustomStringConvertible {
    case Zero
    case One
    case Tuple((Id, Id))
    
    public var description :String { get {
        switch self{
        case .Zero: return "0"
        case .One: return "1"
        case .Tuple(let a, let b): return "(\(a), \(b))"
        }
        }}
    
    public init() {
        self = .One
    }
    
    public init(_ value:Id) {
        self = value
    }
    
    public init(_ left:Id, _ right:Id) {
        self = Id.Tuple(left, right)
    }
    
    func split ()-> (Id, Id) {
        switch self {
        case .Zero:
            return (.Zero, .Zero)
        case .One:
            return (Id(Id(.One), Id(.Zero)), Id(Id(.Zero), Id(.One)))
        case .Tuple(let val):
            switch val {
            case (.Zero, let right):
                let (i1, i2) = right.split()
                return (Id(.Zero,i1),Id(.Zero, i2))
            case (let left, .Zero):
                let (i1, i2) = left.split()
                return (Id(i1, .Zero),Id(i2, .Zero))
            case (let left, let right):
                return (Id(left, .Zero), Id(.Zero,right))
            }
        }
    }
    
    func norm() -> Id {
        switch self {
        case .Tuple(.One, .One):
            return Id(.One)
            
        case .Tuple(.Zero, .Zero):
            return Id(.Zero)
        default:
            return self
        }
    }
}

func +(lhs: Id, rhs: Id) -> Id {
    switch (lhs, rhs){
    case (.Zero, let val):
        return val
    case (let val, .Zero):
        return val
    case (.Tuple(let t1), .Tuple(let t2)):
        return Id(t1.0+t2.0, t1.1+t2.1).norm()
    default:
        print("Invalid addition")
        assert(false)
        return .Zero
    }
}



public indirect enum Event : Equatable, CustomStringConvertible {
    case N(Int)
    case Tuple(Int, Event, Event)
    
    public var description:String { get {
        switch self {
        case .N(let n):
            return "\(n)"
        case .Tuple(let n, let e1, let e2):
            return "(\(n), \(e1), \(e2))"
        }
        }}
    
    public init (_ n:Int, _ e1:Int, _ e2:Int) {
        self = .Tuple(n, .N(e1), .N(e2))
    }
    
    public init (_ n:Int, _ e1:Event, _ e2:Event) {
        self = .Tuple(n, e1, e2)
    }

    
    public init (_ n:Int) {
        self = .N(n)
    }
    
    func lift(m:Int) -> Event{
        switch self {
        case .N(let n):
            return .N(n+m)
        case .Tuple(let (n, e1, e2)):
            return .Tuple(n+m,e1,e2)
        }
    }
    
    func sink(m:Int) -> Event{
        switch self {
        case .N(let n):
            return .N(n-m)
        case .Tuple(let (n, e1, e2)):
            return .Tuple(n-m,e1,e2)
        }
    }
    
    func minimum() -> Int {
        switch self {
        case .N(let n):
            return n
        case .Tuple(let (n, e1, e2)):
            return n + min(e1.minimum(), e2.minimum())
        }
    }
    
    func maximum() -> Int {
        switch self {
        case .N(let n):
            return n
        case .Tuple(let (n, e1, e2)):
            return n + max(e1.maximum(), e2.maximum())
        }
    }
    
    func norm() -> Event {
        switch self {
        case .N:
            return self
        case .Tuple(let(n, e1, e2)):
            switch (e1,e2) {
            case (.N(let m1), .N(let m2)): if m1 == m2 { return  .N(n + m1) }
            default: break
            }
            let m = min(e1.minimum(), e2.minimum())
            return .Tuple(n+m, e1.sink(m), e2.sink(m))
        }
    }
}

public func ==(lhs:Event, rhs: Event) -> Bool {
    switch (lhs, rhs) {
    case (.N(let n1),.N(let n2)):
        return n1 == n2
    case (.Tuple(let (n1, l1, r1)), .Tuple(let (n2, l2, r2))):
        return (n1 == n2) && (l1 == l2) && (r1 == r2)
    default:
        return false
    }
}

public func <=(lhs:Event, rhs: Event) -> Bool{
    switch (lhs, rhs) {
    case (.N(let n1), .N(let n2)): return n1 <= n2
    case (.N(let n1), .Tuple(let (n2, _, _))): return n1 <= n2
    case (.Tuple(let (n1, l1, r1)), .N(let n2)):
        return (n1 <= n2) && (l1.lift(n1) <= rhs) && (r1.lift(n1) <= rhs)
    case (.Tuple(let (n1, l1, r1)), .Tuple(let (n2, l2, r2))):
        return (n1 <= n2) && l1.lift(n1) <= l2.lift(n2) && r1.lift(n1) <= r2.lift(n2)
    }
}



func join(e1:Event,_ e2:Event) -> Event {
    switch (e1, e2) {
    case (.N(let n1), .N(let n2)):
        return Event.N(max(n1, n2))
    case (.N(let n1), .Tuple(let (n2, l2, r2))):
        let ev1 = Event(n1, 0, 0)
        let ev2 = Event.Tuple(n2, l2, r2)
        return join( ev1, ev2)
        
    case (.Tuple(let (n1, l1, r1)), .N(let n2)):
        return join(Event.Tuple(n1, l1, r1), Event(n2, 0, 0))
        
    case (.Tuple(let (n1, l1, r1)), .Tuple(let (n2, l2, r2))):
        if n1 > n2 {
            return join(e2, e1)
        } else {
            return Event.Tuple(n1, join(l1, l2.lift(n2-n1)), join(r1, r2.lift(n2-n1))).norm()
        }
        
    }
}
let joinEvent = join




public struct Stamp : CustomStringConvertible {
    static let largeConstant = 1000
    var id:Id
    private(set) public var e:Event
    
    public var description: String { get { return "(\(id), \(e))"} }
    
    public init () {
        id = Id()
        e = Event(0)
    }
    
    init (_ id:Id, _ event:Event) {
        self.id = id
        self.e = event
    }
    
    public mutating func fork() -> Stamp {
        let (i1,i2) = id.split()
        id = i1
        return Stamp(i2, e)
    }
    
    func fill() -> Event {
        switch (id, e) {
        case (.Zero, let e):
            return e
        case (.One, let e):
            return Event.N(e.maximum())
        case (_, .N):
            return e
        case (.Tuple(.One, let ir), .Tuple(let (n, el, er))):
            let er_ = Stamp(ir, er).fill()
            return Event.Tuple(n, Event.N(max(el.maximum(), er_.minimum())), er_).norm()
            
        case (.Tuple(let il, .One), .Tuple(let (n, el, er))):
            let el_ = Stamp(il, el).fill()
            return Event.Tuple(n, el_, Event.N(max(er.maximum(), el_.minimum()))).norm()
        
        case (.Tuple(let (il, ir)), .Tuple(let (n, el, er))):
            return Event.Tuple(n, Stamp(il, el).fill(), Stamp(ir, er).fill()).norm()
        default:
            assert(false) // Should never happen
            return Event(0)
        }
    }
    
    func grow() -> (Event, Int) {
        switch (id, e) {
        case (.One, .N(let n)):
            return (Event(n+1), 0)
        case (let i, .N(let n)):
            let (e_,c) = Stamp(i, Event(n, 0, 0)).grow()
            return (e_, c + Stamp.largeConstant)
        case (.Tuple(.Zero, let ir), .Tuple(let (n, el, er))):
            let (er_, cr) = Stamp(ir, er).grow()
            return (Event(n, el, er_), cr+1)
        
        case (.Tuple(let il, .Zero), .Tuple(let (n, el, er))):
            let (el_, cl) = Stamp(il, el).grow()
            return (Event(n, el_, er), cl + 1)
            
        case (.Tuple(let (il, ir)), .Tuple(let (n, el, er))):
            let (el_, cl) = Stamp(il, el).grow()
            let (er_, cr) = Stamp(ir, er).grow()
            
            if cl < cr {
                return (Event(n,el_,er),cl+1)
            } else {
                return (Event(n,el,er_),cr+1)
            }
        default:
            assert(false) // Should never happen
            return (Event(0),0)
        }
    }
    
    public mutating func event() {
        
        let eFilled = self.fill()
        if eFilled != e {
             e = eFilled
        } else {
            let (e_, _) = self.grow()
            e = e_
        }
    }
    
    public mutating func join(b:Stamp) {
        id = id+b.id
        e = joinEvent(e, b.e)
    }
    
}


