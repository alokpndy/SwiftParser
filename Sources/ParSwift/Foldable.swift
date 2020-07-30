//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation

public protocol Foldable {
    associatedtype A
    associatedtype B
    func foldr(_ folder : (A) -> (B) -> B, _ initial : B) -> B
}
