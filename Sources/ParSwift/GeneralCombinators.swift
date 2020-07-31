//
//  File.swift
//  
//
//  Created by Alok pandey on 31/07/20.
//

import Foundation

public func anyCharP() -> ParserT<Character> {
        return ParserT<Character>({ (x : String) in
            if let c : Character = x.first {
                return Optional(( c, String(x.dropFirst())) )
            }
            return nil
        })
}


public func charP (_ char : (Character)) -> ParserT<Character> {
    let cP
        = ParserT<Character>({ (x : String) in
            char == x.first ? Optional((char, String(x.dropFirst()))) : nil  })
    return cP
}

public func stringLiteral() -> ParserT<String> {
    return StateT({ str in
        if let (xs, ys) = spanP( { xs in xs != "\""}  , str.map { String($0) }) {
            return (xs.joined(separator: ""), ys.joined(separator: ""))
        } else { return nil }
    })
}

public func str() -> ParserT<String> {
    return ( {x in String(x)} <^> charP("\"")) *> stringLiteral() <* ({x in String(x)} <^>  charP("\""))
}

public func manyTill<A>(many : ParserT<A>, till : ParserT<A> ) -> ParserT<[A]> {
    return StateT ({ str in
        func many1 (_ xs : String) -> [(A, String)] {
            
            if let _ = till.runStateT(xs) {
                return  []
            } else {
                if let (s1,x1) = many.runStateT(xs) {
                    return ([(s1,x1)] + many1(x1))
                }
                else { return ([] + many1( String(xs.dropFirst()) )) }
            }
        }
        let res = many1(str)
        let values = res.map( { x in x.0 } )
        let unconsumed = res.last
        let ret : ([A], String)  = (res.count > 0) ? (values, unconsumed!.1) : ([], str)
        return ret
    })
}

public func bracketP() -> ParserT<String> {
    let t = {x in String(x)} <^>  manyTill(many: anyCharP(), till: charP(")"))
    return ( {x in String(x)} <^> charP("(")) *> ( t <* ({x in String(x)} <^>  charP(")")))
}

public func some1<A>(_ parser : ParserT<A>) -> ParserT<[A]> {
   
    return StateT ({ str in
        
        func many (_ xs : String) -> [(A, String)] {
            if let (s,x) = (parser).runStateT(xs) {
                return ([(s,x)] + many(x))
            } else {
                return []
            }
        }
        
        let res = many(str)
        let values = res.map( { x in x.0 } )
        let unconsumed = res.last
        let ret : ([A], String)  = (res.count > 0) ? (values, unconsumed!.1) : ([], str)
        return ret
    })
}
