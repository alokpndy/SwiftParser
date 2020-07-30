//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation

protocol Applicative : Functor {
    associatedtype B
    associatedtype FAB = K1<(A) -> B>
    
    static func pure(_ : A) -> Self
    func ap(_ f : FAB) -> FB
}


protocol Alternative : Applicative {
    associatedtype FC = K2<A,B>
    // Identity of <|> monoid
    static func empty() -> FC
    // An associative binary operation
    func alt (_ fst: FC) -> FC
   
}
