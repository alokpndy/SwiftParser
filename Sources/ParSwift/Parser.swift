//
//  File.swift
//  
//
//  Created by Alok pandey on 29/07/20.
//

import Foundation

public indirect enum JsonValue  {
    case JsonNull
    case JsonBool (Bool)
    case JsonString (String)
    case JsonNumber (Int)
    case JsonArray ([JsonValue])
    case JsonObject ([(String, JsonValue)])
}

extension JsonValue : CustomStringConvertible {
    public var description: String {
        switch self {
        case .JsonNull:
            return "JSON Null"
        case let .JsonBool(value):
            return "JSON Bool" + String(value)
        default:
            return "lse"
        }
    }
    
    
}

func getValue(_ a: JsonValue) -> [(String,JsonValue)] {
    switch a {
    case let .JsonObject(value):
        return value
    default:
        return []
    }
}
