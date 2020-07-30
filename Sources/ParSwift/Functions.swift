//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation


infix operator <^> : FunctionArrowPrecedence
func <^> <S, A, B>(_ f : @escaping (A) -> B, s : StateT<S, A>) -> StateT<S, B> {
    return s.fmap(f)
}

infix operator <|> : FunctionArrowPrecedence
func <|> <S, A>(_ f : StateT<S, A> , s : StateT<S, A>) -> StateT<S, A> {
    return s.alt(f)
}

infix operator *> : FunctionArrowPrecedence
func *> <S, A>(_ a : StateT<S, A> , b : StateT<S, A>) -> StateT<S, A> {
    return StateT ( { str in
        if let (_,xs) = a.runStateT(str) {
            if let (s2,ys) = b.runStateT(xs) {
                return (s2,ys)
            } else { return nil }
        } else { return nil }
    })
}

infix operator <* : FunctionArrowPrecedence
func <* <S, A>(_ a : StateT<S, A> , b : StateT<S, A>) -> StateT<S, A> {
    return StateT ( { str in
        if let (s1,xs) = a.runStateT(str) {
            if let (_,ys) = b.runStateT(xs) {
                return (s1,ys)
            } else { return nil }
        } else { return nil }
    })
}



func const<A>(_ first : A) ->  (_ snd: Any) -> A {
    return {x in first }
}


func span<A>(_ check: (A) -> Bool, _ ls: [A]) -> ([A], [A]) {
    switch ls.match {
    case .Nil:
        return ((([], [])) as! ([A], [A]))
    case let .Cons(x, xs):
        if (check(x)) == true {
            let (a,b) = span(check, xs)
            return ([x] + a, b)
           // return (matches.append(x), xs)
        } else { return (Optional(([], ([x]+xs))) as! ([A], [A])) }
       
    }
}

func spanP<A>(_ check: (A) -> Bool, _ ls: [A]) -> ([A], [A])? {
    let (xs,_) = span(check, ls)
    switch xs.match {
    case .Nil:
        return nil
    default:
        return Optional(span(check, ls))
    }
}

func isDigit(_ c: String) -> Bool {
    if Int(c) == nil {
        return false
    } else {
        return true
    }
}



func makeTuple<A,B>(_ x: A) -> (B) -> (A, B) {
    return { y in  (x,y)}
}
