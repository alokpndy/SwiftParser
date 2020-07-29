import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

public class K1<A> { public init() {} }
public class K2<A,B> { public init() {} }

public protocol Functor {
    associatedtype A
    associatedtype B
    associatedtype FB =  K2<B,B>
    func fmap(_ f : @escaping(A) -> B) -> FB
}

struct StateT<S,A>  {
    let runStateT : (S) -> Optional<(A,S)>
    init(_ runStateT : @escaping (S) -> Optional<(A, S)>) {
            self.runStateT = runStateT
        }
}

extension StateT : Functor {
    typealias FB = StateT<S,B>
    typealias B = Any
    
    func fmap<B>(_ f : @escaping (A) -> B) -> StateT<S,B> {
            return StateT<S,B> { s in
                if let (val, st2) = self.runStateT(s) {
                    return (f(val), st2)
                } else { return nil }
                
            }
        }
}


infix operator <^> : FunctionArrowPrecedence
func <^> <S, A, B>(_ f : @escaping (A) -> B, s : StateT<S, A>) -> StateT<S, B> {
    return s.fmap(f)
}

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



public protocol Foldable {
    associatedtype A
    associatedtype B
    func foldr(_ folder : (A) -> (B) -> B, _ initial : B) -> B
}



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

typealias ParserT<B> = StateT<String,B>


func charP (_ char : (Character)) -> ParserT<Character> {
    let cP
        = ParserT<Character>({ (x : String) in
            char == x.first ? Optional((char, String(x.dropFirst()))) : nil  })
    return cP
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
    

public indirect enum JsonValue {
    case JsonNull
    case JsonBool (Bool)
    case JsonString (String)
    case JsonNumber (Int)
    case JsonArray ([JsonValue])
    case JsonObject ([(String, JsonValue)])
}

func getValue(_ a: JsonValue) -> [(String,JsonValue)] {
    switch a {
    case let .JsonObject(value):
        return value
    default:
        return []
    }
}




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


func stringLiteral() -> ParserT<String> {
    return StateT({ str in
        if let (xs, ys) = spanP( { xs in xs != "\""}  , str.map { String($0) }) {
            return (xs.joined(separator: ""), ys.joined(separator: ""))
        } else { return nil }
    })
}

func str() -> ParserT<String> {
    return ( {x in String(x)} <^> charP("\"")) *> stringLiteral() <* ({x in String(x)} <^>  charP("\""))
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



var jsonParser = jsonNull() <|> jsonBool() <|> jsonNumber() <|> jsonStr()

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



func jsonArray() -> ParserT<JsonValue> {
    let left : ParserT<[JsonValue]> = {x in [] } <^> charP("[")
    let right : ParserT<[JsonValue]> = const([]) <^> charP("]")
    return ( { x in JsonValue.JsonArray(x)} <^> (left *> some() <* right))
}

jsonParser = jsonParser <|> jsonArray()


func jsonTuple() -> ParserT<JsonValue> {
    let comma : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP(",")
    let pp : ParserT<(JsonValue) -> (String,JsonValue)>  = { x in return makeTuple(x)} <^> str()
    let cp : ParserT<JsonValue> = ({x in JsonValue.JsonNull } <^> charP(":"))
    let p2 : ParserT<JsonValue> = cp *> jsonParser
    let p3 : ParserT<(JsonValue)> = {x in JsonValue.JsonObject([x])} <^> (pp <*> p2)
    let left : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP("{")
    let right : ParserT<JsonValue> = const(JsonValue.JsonNull) <^> charP("}")
    let obp = (p3 <|> (comma *> p3))
    
   // return obp
    
    
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
func jsonObject() -> ParserT<JsonValue> {
    let left : ParserT<JsonValue> = {x in JsonValue.JsonNull } <^> charP("{")
    let right : ParserT<JsonValue> = const(JsonValue.JsonNull) <^> charP("}")
    return (left *> jsonTuple() <* right)
}



func makeTuple<A,B>(_ x: A) -> (B) -> (A, B) {
    return { y in  (x,y)}
}

jsonParser = jsonParser <|> jsonObject()


//print((jsonObject().runStateT("{\"key\":true,\"key2\":false,\"key3\":{\"key4\":null}}")))


//let path = playgroundSharedDataDirectory.appendingPathComponent("json.txt")

//print(try String(contentsOf: path, encoding: .utf8))


let url = URL(string: "https://raw.githubusercontent.com/alokpndy/SwiftParser/master/sts.json")!

let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
    print("oooo")
    if let localURL = localURL {
        
        if let string = try? String(contentsOf: localURL) {
            print("string111")
            print(jsonParser.runStateT(string))
            print("string")
        }
    }
}

task.resume()

//print(jsonParser.runStateT("[{\"key\":\"keyv\",\"key\":[{\"key\":true,\"key\":true}]}]"))

