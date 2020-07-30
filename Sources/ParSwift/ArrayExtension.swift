//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation

public enum ArrayMatcher<A> {
    case Nil
    case Cons(A, [A])
}

extension Array {
    public var match : ArrayMatcher<Element> {
        if self.count == 0 {
            return .Nil
        } else if self.count == 1 {
            return .Cons(self[0], [])
        }
        let hd = self[0]
        let tl = Array(self[1..<self.count])
        return .Cons(hd, tl)
    }
    
}
public func uncurry<A, B, C>(_ f : @escaping (A) -> (B) -> C) -> (A, B) -> C {
   return { a, b in f(a)(b) }
}

extension Array /*: Foldable*/ {
    public func foldr<B>(_ k : @escaping (Element) -> (B) -> B, _ i : B) -> B {
        switch self.match {
        case .Nil:
            return i
        case let .Cons(x, xs):
            return k(x)(xs.foldr(k, i))
        }
    }
}
