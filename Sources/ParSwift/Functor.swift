//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation

public protocol Functor {
    associatedtype A
    associatedtype B
    associatedtype FB =  K2<B,B>
    func fmap(_ f : @escaping(A) -> B) -> FB
}


