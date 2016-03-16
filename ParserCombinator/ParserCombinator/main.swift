//
//  main.swift
//  ParserCombinator
//
//  Created by wenjin on 3/16/16.
//  Copyright © 2016 wenjin. All rights reserved.
//

import Foundation


extension CollectionType
    where Generator.Element == SubSequence.Generator.Element
{
    var decompose : (head : Generator.Element,tail : [Generator.Element])?{
        guard let head = first else {return nil}
        
        return (head,Array(dropFirst()))
    }
    
}

struct Parser<a>{
    let p : String -> [(a,String)]
    
}

infix operator >>= {associativity left precedence 130}

func >>= <a,b>(p : Parser<a>, f : a->Parser<b>) -> Parser<b>{
    return Parser { cs in
        let p1 = parse(p, input: cs)
        guard p1.count>0 else{
            return []
        }
        let p = p1[0]
        
        let p2 = parse(f(p.0), input: p.1)
        guard p2.count > 0 else{
            return []
        }
        
        return p2
    }
}

func pure<a>( item : a) -> Parser<a>{
    return Parser { cs in
        return [(item,cs)]
    }
}



func parserChar(c : Character) -> Parser<Character>{
    return Parser { x in
        guard let head = x.characters.first where head == c else{
            return []
        }
        return [(c,String(x.characters.dropFirst()))]
        
    }
}

func parse<a>(parser : Parser<a> , input: String) -> [(a,String)]{
    var result :[(a,String)] = []
    for (x,s) in parser.p(input){
        result.append((x,s))
    }
    return result
}


func satify(condition : Character -> Bool) -> Parser<Character>{
    return Parser { x in
        guard let head = x.characters.first where condition(head) else{
            return []
        }
        return [(head,String(x.characters.dropFirst()))]
    }
}


//
//func symbol<Token : Equatable>(sym : Token) -> Parser<Token,Token>{
//    return satify{$0 == sym}
//}
//
//infix operator <|> {associativity right precedence 130}
//
//func <|> <Token,A> (l : Parser<Token,A> , r: Parser<Token,A>) -> Parser<Token,A> {
//    return Parser{ AnySequence(r.p($0).generate() + l.p($0).generate())}
//}


func parserABC() -> Parser<String>{
    return parserChar("a") >>= { x in
        return parserChar("b") >>= { y in
            return parserChar("c") >>= { z in
                var chs:[Character] = []
                chs.append(x)
                chs.append(y)
                chs.append(z)
                let str = String(chs)
                return pure(str)
            }
        }
    }
}

func +<G:GeneratorType, H:GeneratorType where G.Element == H.Element>(var first : G ,var second:H) -> AnyGenerator<G.Element>{
    return anyGenerator{first.next() ?? second.next()}
}

print("Hello, World!")

let a:String = "a"
let b: String = "abcergebac"
print (parse(parserABC(), input: b))
//print (parse(symbol("a") <|> symbol("a"), input: "abcd"))


