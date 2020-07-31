//
//  File.swift
//  
//
//  Created by Alok pandey on 30/07/20.
//

import Foundation


public struct Kindle {
    
    public enum Category {
        case Highlight
        case Bookmark
        case Note
    }
    
    public enum Clipping {
        case Author (String)
        case Book (String)
        case Type (Category)
        case Location (Int,Int)
        case CDate (String) // for now
    }
    
    
    func jsonStr() -> ParserT<Clipping> {
        return ({x in return Clipping.Author(x)} <^> str())
    }
     
}

let kindle = Kindle()


let cst = """
4: Harry Potter and the Goblet of Fire (J.K. Rowling)
- Your Highlight on Location 8866-8867 | Added on Monday, February 2, 2015 9:42:48 AM

If you want to know what a man’s like, take a good look at how he treats his inferiors, not his equals.”
==========
7: Harry Potter and the Deathly Hallows (J.K. Rowling)
- Your Highlight on Location 5172-5172 | Added on Tuesday, February 3, 2015 10:54:39 PM

Where your treasure is, there will your heart be also.
==========
"""
