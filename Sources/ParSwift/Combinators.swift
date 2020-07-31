//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation






public struct Combinators {

    public var jsonParser : ParserT<JsonValue> {
        get {
            return (jsonNull() <|> jsonBool() <|> jsonNumber() <|> jsonStr() <|> jsonArray() <|> jsonObject())
        }
    }
    
    init() {}
    
    
    


    func jsonString (str : String) -> ParserT<[Character]> {
        let parsers = str.map(charP(_:))
        let strParser = parsers.foldr({ x in return { y in return   ( y.ap(x.fmap({ x1 in return { s in ([x1] + s)} } )) ) as StateT<String,[Character]>   } }, (StateT.pure([])) )
        return strParser
    }

    func jsonNumber() -> ParserT<JsonValue> {
        return StateT({ str in
            if let (xs, ys) = spanP( isDigit(_:) , str.map { String($0) }) {
                let chs : String = xs.joined(separator: "")
                let nums = Int(String(chs))
                
                return (JsonValue.JsonNumber(nums!), ys.joined(separator: ""))
            } else { return nil }
        })
    }


  


    func jsonStr() -> ParserT<JsonValue> {
        return ({x in return JsonValue.JsonString(x)} <^> str())
    }

    func jsonNull() -> ParserT<JsonValue> {
        let parserResult = jsonString(str: "null")
        return parserResult.fmap(const(_:JsonValue.JsonNull))
    }

    func jsonBool() -> ParserT<JsonValue> {
        let parserResult = ((jsonString(str: "true").fmap(const(_:JsonValue.JsonBool(true)))) ).alt((jsonString(str: "false")).fmap(const(_:JsonValue.JsonBool(false))))
        return parserResult
    }





    func some() -> ParserT<[JsonValue]> {
        let comma : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP(",")
        
        return StateT ({ str in
            
            func many (_ xs : String) -> [(JsonValue, String)] {
                if let (s,x) = (self.jsonParser <|> (comma  *> self.jsonParser )).runStateT(xs) {
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



    func jsonArray() -> ParserT<JsonValue> {
        let left : ParserT<[JsonValue]> = {x in [] } <^> charP("[")
        let right : ParserT<[JsonValue]> = const([]) <^> charP("]")
        return ( { x in JsonValue.JsonArray(x)} <^> (left *> some() <* right))
    }

        
   
    func manyy(_ jsonP :  ParserT<JsonValue>) -> ParserT<[JsonValue]> {
        let comma : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP(",")
        return StateT ({ str in
            
            func many (_ xs : String) -> [(JsonValue, String)] {
                if let (s,x) = (jsonP <|> (comma  *> jsonP )).runStateT(xs) {
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



    func jsonObject() -> ParserT<JsonValue> {
        
        let keyParser : ParserT<(JsonValue) -> (String,JsonValue)>  = { x in return makeTuple(x)} <^> (str() <* ({x in "empty"} <^> charP(":")))
        
        let listParser : ParserT<JsonValue> = {x in JsonValue.JsonObject([x])} <^> (keyParser <*> (jsonNull() <|> jsonBool() <|> jsonNumber() <|> jsonStr() <|> jsonArray()) )
        
        let left : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP("{")
        let right : ParserT<JsonValue> = const(JsonValue.JsonNull) <^> charP("}")
        return (left *>  ({ x in JsonValue.JsonObject(x.flatMap(getValue(_:))) } <^>  manyy(listParser)) <* right)
    }



   

}
