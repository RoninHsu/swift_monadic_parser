//
//  Parser.swift
//  ParserCombinator
//
//  Created by aaaron7 on 16/3/16.
//  Copyright © 2016年 wenjin. All rights reserved.
//

import Foundation

struct Parser<a>{
    let p : String -> [(a,String)]

}


// Utility function
func isSpace(c : Character) -> Bool{
    let s = String(c)
    let result = s.rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    return result != nil
}

func isDigit(c : Character) -> Bool{
    let s = String(c)
    return Int(s) != nil
}

func isAlpha(c : Character) -> Bool{
    if c >= "a" && c <= "z" || c >= "A" && c <= "Z"{
        return true
    }else{
        return false
    }
}

//MARK: Basic Element

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

func satify(condition : Character -> Bool) -> Parser<Character>{
    return Parser { x in
        guard let head = x.characters.first where condition(head) else{
            return []
        }
        return [(head,String(x.characters.dropFirst()))]
    }
}



//MARK: combinator

infix operator +++ {associativity left precedence 130}
func +++ <a>(l : Parser<a>, r:Parser<a>) -> Parser<a>   {
    return Parser { x in
        if l.p(x).count > 0{
            return l.p(x)
        }else{
            return r.p(x)
        }
    }
}



func many<a>(p: Parser<a>) -> Parser<[a]>{
    return many1(p) +++ pure([])
}

func many1<a>(p : Parser<a>) -> Parser<[a]>{
    return p >>= { x in
        return many(p) >>= { xs in
            return pure([x] + xs)
        }
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



//MARK: handle string
func string(str : String) -> Parser<String>{
    guard str != "" else{
        return pure("")
    }

    let head = str.characters.first!
    return parserChar(head) >>= { c in
        string(String(str.characters.dropFirst())) >>= { cs in
            let result = [c] + cs.characters
            return pure(String(result))
        }
    }
}

func space()->Parser<String>{
    return many(satify(isSpace)) >>= { x in
        return pure("")
    }
}

func symbol(sym : String) -> Parser<String>{
    return string(sym) >>= { sym in
        return space() >>= { _ in
            return pure(sym)
        }
    }
}




//MARK: process numbers
func digit() -> Parser<Exp>{
    return satify(isDigit) >>= { x in
        let p = Exp.Constant(Int(String(x))!)
        return pure(p)
    }
}

func number() -> Parser<Exp>{
    return many(digit()) >>= { cs in
        space() >>= { _ in
            let sum = cs.reduce(Exp.Constant(0), combine: { (exp1 , exp2 ) -> Exp in
                return Exp.Constant((exp1.pConstant * 10 + exp2.pConstant))
            })
            return pure(sum)
        }
    }
}


//MARK: handle expression

func identifier() -> Parser<String>{
    return satify(isAlpha) >>= { c in
        return many(satify({ (c) -> Bool in
            return isAlpha(c) || isDigit(c)
        })) >>= { cs in
            return space() >>= { _ in
                return pure(String([c] + cs))
            }
        }
    }
}

func variables() -> Parser<Exp>{
    return identifier() >>= { name in
        return pure(Exp.Var(name))
    }
}

func factor()->Parser<Exp>{
    return variables() +++ number() +++ (symbol("(") >>= { _ in
        return expr() >>= { n in
            return symbol(")") >>= { _ in
                return pure(n)
            }
        }
    })
}

func expr() -> Parser<Exp>{

}

