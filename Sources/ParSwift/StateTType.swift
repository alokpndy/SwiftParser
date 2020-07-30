//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation



public struct StateT<S,A>  {
    public let runStateT : (S) -> Optional<(A,S)>
    init(_ runStateT : @escaping (S) -> Optional<(A, S)>) {
            self.runStateT = runStateT
        }
}


extension StateT : Functor {
    public typealias FB = StateT<S,B>
    public typealias B = Any
    
    public func fmap<B>(_ f : @escaping (A) -> B) -> StateT<S,B> {
            return StateT<S,B> { s in
                if let (val, st2) = self.runStateT(s) {
                    return (f(val), st2)
                } else { return nil }
                
            }
        }
}




extension StateT : Applicative {
    
    typealias FAB = StateT<S, (A) -> B>

    func ap<B>(_ sab: StateT<S, (A) -> B>) -> StateT<S, B> {
        return StateT<S,B>{ str in
            if let (fab, s1) = sab.runStateT(str) {
                if let (a,s2) = self.runStateT(s1)  {
                    return (fab(a), s2)
                } else { return nil }
            } else { return nil }
        }
    }
    
    static func pure(_ a : A) -> StateT<S, A> {
        return StateT { s in (a,s) }
    }
}



infix operator <*> : FunctionArrowPrecedence
func <*> <S, A, B>(_ f : StateT<S, (A) -> B> , s : StateT<S, A>) -> StateT<S, B> {
    return s.ap(f)
}



extension StateT : Alternative {
        
    typealias C = FAB
    
    static func empty() -> StateT<S, A>  {
        return StateT.init({ _ in return nil})
    }
    // <|>   A monoid on applicative functors.
    func alt(_ fst : StateT<S, A>) -> StateT<S, A> {
        return StateT({str in
            if let s1 = self.runStateT(str) {
                return s1
            } else {
                if let s2 = fst.runStateT(str) {
                    return s2
                } else {
                    return nil
                }
            }
        })
    }
    
}


public typealias ParserT<B> = StateT<String,B>
