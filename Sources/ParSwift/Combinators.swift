//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation

public struct Combinators {

    public var jsonParser : (ParserT<JsonValue>)!


    public func charP (_ char : (Character)) -> ParserT<Character> {
        let cP
            = ParserT<Character>({ (x : String) in
                char == x.first ? Optional((char, String(x.dropFirst()))) : nil  })
        return cP
    }


    public func jsonString (str : String) -> ParserT<[Character]> {
        let parsers = str.map(charP(_:))
        let strParser = parsers.foldr({ x in return { y in return   ( y.ap(x.fmap({ x1 in return { s in ([x1] + s)} } )) ) as StateT<String,[Character]>   } }, (StateT.pure([])) )
        return strParser
    }

    public func jsonNumber() -> ParserT<JsonValue> {
        return StateT({ str in
            if let (xs, ys) = spanP( isDigit(_:) , str.map { String($0) }) {
                let chs : String = xs.joined(separator: "")
                let nums = Int(String(chs))
                
                return (JsonValue.JsonNumber(nums!), ys.joined(separator: ""))
            } else { return nil }
        })
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


    public func jsonStr() -> ParserT<JsonValue> {
        return ({x in return JsonValue.JsonString(x)} <^> str())
    }

    public func jsonNull() -> ParserT<JsonValue> {
        let parserResult = jsonString(str: "null")
        return parserResult.fmap(const(_:JsonValue.JsonNull))
    }

    public func jsonBool() -> ParserT<JsonValue> {
        let parserResult = ((jsonString(str: "true").fmap(const(_:JsonValue.JsonBool(true)))) ).alt((jsonString(str: "false")).fmap(const(_:JsonValue.JsonBool(false))))
        return parserResult
    }





    func some() -> ParserT<[JsonValue]> {
        let comma : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP(",")
        
        return StateT ({ str in
            
            func many (_ xs : String) -> [(JsonValue, String)] {
                if let (s,x) = (jsonParser <|> (comma  *> jsonParser )).runStateT(xs) {
                    return ([(s,x)] + many(x))
                } else {
                    return []
                }
            }
            
            let res = many(str)
            let values = res.map( { x in x.0 } )
            let unconsumed = res.last
            let ret : ([JsonValue], String)  = (res.count > 0) ? (values, unconsumed!.1) : ([], str)
            return ret
        })
    }



    public func jsonArray() -> ParserT<JsonValue> {
        let left : ParserT<[JsonValue]> = {x in [] } <^> charP("[")
        let right : ParserT<[JsonValue]> = const([]) <^> charP("]")
        return ( { x in JsonValue.JsonArray(x)} <^> (left *> some() <* right))
    }




    public func jsonTuple() -> ParserT<JsonValue> {
        let comma : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP(",")
        let pp : ParserT<(JsonValue) -> (String,JsonValue)>  = { x in return makeTuple(x)} <^> str()
        let cp : ParserT<JsonValue> = ({x in JsonValue.JsonNull } <^> charP(":"))
        let p2 : ParserT<JsonValue> = cp *> jsonParser
        let p3 : ParserT<(JsonValue)> = {x in JsonValue.JsonObject([x])} <^> (pp <*> p2)
        let obp = (p3 <|> (comma *> p3))
        
        return StateT ({ str in
            
            func many (_ xs : String) -> [(JsonValue, String)] {
                if let (s,x) = obp.runStateT(xs) {
                    return ([(s,x)] + many(x))
                } else {
                    return []
                }
            }
            
            let res = many(str)
            let values = res.map( { x in x.0 } )
            let unconsumed = res.last
            let ret : (JsonValue, String)  = (res.count > 0) ? (JsonValue.JsonObject( (values.map({x in getValue(x)})).flatMap( {x in x })   ), unconsumed!.1) : (JsonValue.JsonObject([]), str)
            return ret
        })
    }
    public func jsonObject() -> ParserT<JsonValue> {
        let left : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP("{")
        let right : ParserT<JsonValue> = const(JsonValue.JsonNull) <^> charP("}")
        return (left *> jsonTuple() <* right)
    }
    
    public init() {
        self.jsonParser = jsonNull() <|> jsonBool() <|> jsonNumber() <|> jsonStr() <|> jsonArray() <|> jsonParser <|> jsonObject()
    }
    

    
}

