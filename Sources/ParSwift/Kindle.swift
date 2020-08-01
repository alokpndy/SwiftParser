//
//  File.swift
//  
//
//  Created by Alok pandey on 30/07/20.
//

import Foundation


public struct KindleParser {
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


    

    public func manyTill(many : ParserT<Character>, till : ParserT<Character> ) -> ParserT<[Character]> {
        return StateT ({ str in
            func many1 (_ xs : String) -> [(Character, String)] {
                
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
            let ret : ([Character], String)  = (res.count > 0) ? (values, unconsumed!.1) : ([], str)
            return ret
        })
    }



        
    public func anyCharP() -> ParserT<Character> {
            return ParserT<Character>({ (x : String) in
                if let c : Character = x.first {
                    return Optional(( c, String(x.dropFirst())) )
                }
                return nil
            })
    }
         



    

    // "highlight|выделенный|Markierung|subrayado|surlignement|evidenziazione|ハイライト|destaque|标"
    // note|のメモ|笔记|заметка|nota|notitie|Notiz



    public func bracketP() -> ParserT<String> {
        let t = {x in String(x)} <^>  manyTill(many: anyCharP(), till: charP(")"))
        return ( {x in String(x)} <^> charP("(")) *> ( t <* ({x in String(x)} <^>  charP(")")))
    }

    public func bookP() -> ParserT<[Character]> {
        return (manyTill(many: anyCharP(), till: ( (const("\0") <^> bracketP()) *>  charP("\n")) ))
    }
    public func authorP() -> ParserT<String> {
        return bracketP()
    }

    public func categoryP() -> ParserT<[Character]> {
        return manyTill(many: anyCharP() <|> anyCharP(), till: (const("s") <^> charP("|")))
    }

    public func dateP() -> ParserT<[Character]> {
        return manyTill(many: anyCharP(), till: (const("s") <^> charP("\n")))
    }

    public func clipP() -> ParserT<[Character]> {
        let delim = charP("\n") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") //*> charP("\n")
        return manyTill(many: anyCharP(), till: (const("s") <^> delim ))
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

}



let cst = """
4: Harry Potter (and) the (Goblet) of Fire (J.K. Rowling)
- Your Highlight on Location 8866-8867 | Added on Monday, February 2, 2015 9:42:48 AM

If you want not his equals.”
==========
On paid App Store search results (marco.org)
-  La tua evidenziazione alla posizione 3-4 | Aggiunto in data mercoledì 4 maggio 2016 17:36:35

Apple Inc. has Among the ideas being
==========
DUST ON MOUNTAIN: COLLECTED STORIES (BOND, RUSKIN)
- Votre surlignement à lʼemplacement 144-146 | Ajouté le samedi 26 décembre 2015 11:21:23

For a week, longer probably, I was going to live alone in the red-brick bungalow on the outskirts of the town, on the Apart
==========
Islands in the Stream (Ernest Hemingway)
- Ihre Markierung auf Seite 9 | bei Position 130-131 | Hinzugefügt am Sonntag, 27. Dezember 2015 08:18:36

the narrow tongue of land between the harbor and the open sea. It had lasted through three hurricanes
==========
Red Rising Trilogy - [03.00] - Morning Star: Book III of the Red Rising Trilogy (Pierce Brown)
– Ваш выделенный отрывок на странице 8 | Место 243–245 | Добавлено: пятница, 26 февраля 2016 г. в 11:00:57

Deep in darkness, far from warmth and rock.
==========
Slade House (David Mitchell)
- 27ページ|位置No. 409-412のハイライト |作成日: 2016年2月26日金曜日 11:49:27

The hatch opens and Joy  Joy’s got a Rhodesian accent
==========
India: A History. Revised and Updated (Keay, John)
- Seu destaque ou posição 2025-2026 | Adicionado: sábado, 26 de dezembro de 2015 11:39:48

Overrunning the satellite states and outlying provinces of the Nanda kingdom, the allies eventually converged on Magadha. Pataliputra was probably besieged and,
==========
Joey Pigza - [01.00] - Joey Pigza Swallowed the Key (Jack Gantos)
- 您在第 3 页（位置 #77-78）的标注 | 添加于 2016年2月26日星期五 上午10:56:04

So I went and stood in the hall for about a second until I remembered the mini-Superball in my pocket and started to bounce it off the lockers and ceiling and after Mrs.
==========
"""

let fn : ([Character]) -> (String) -> ([Character]) -> ([Character]) -> ([Character]) -> (String,String,String,String,String) =
    { x in { y in { z in { a in { b in {(String(x) ,String(y), String(z), String(a), String(b))}() }}}}}

let delim = charP("\n") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("=") *> charP("\n")

let dateParser  = (const([]) <^> (charP("|") *> charP(" "))) *> kparser.dateP() <* (const([]) <^> (charP("\n") *> charP("\n")))

let kparser = KindleParser()

let pa = (((((fn <^> kparser.bookP())
                <*> (kparser.authorP() <*  (const("\0") <^> charP("\n")))  )
                <*> ( (const([]) <^> (charP("-") *> charP(" "))) *>  kparser.categoryP())  )
            <*> dateParser )
            <*> (kparser.clipP() <* (const([]) <^> delim)) )
            



let parsed = ( kparser.some1( pa) ).runStateT(cst)




