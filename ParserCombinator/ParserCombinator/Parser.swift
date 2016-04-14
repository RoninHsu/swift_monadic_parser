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

infix operator >>= {associativity left precedence 150}

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

func mzero<a>()->Parser<a>{
    return Parser { xs in [] }
}

func pure<a>( item : a) -> Parser<a>{
    return Parser { cs in [(item,cs)] }
}

func satisfy(condition : Character -> Bool) -> Parser<Character>{
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
        let result = l.p(x)
        if result.count > 0{
            return result
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
        many(p) >>= { xs in
            pure([x] + xs)
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

func parserCharA() -> Parser<Character>{
    let parser =  Parser<Character> { x in
        guard let head = x.characters.first where head == "a" else{
            return []
        }
        return [("a",String(x.characters.dropFirst()))]
    }

    return parser
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
    return many(satisfy(isSpace)) >>= { x in pure("") }
}

func symbol(sym : String) -> Parser<String>{
    return string(sym) >>= { sym in
        space() >>= { _ in
            pure(sym)
        }
    }
}




//MARK: process numbers
func digit() -> Parser<Exp>{
    return satisfy(isDigit) >>= { x in
        pure(Exp.Constant(Int(String(x))!))
    }
}

func number() -> Parser<Exp>{
    return many1(digit()) >>= { cs in
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
    return satisfy(isAlpha) >>= { c in
        many(satisfy({ (c) -> Bool in isAlpha(c) || isDigit(c) })) >>= { cs in
            space() >>= { _ in
                pure(String([c] + cs))
            }
        }
    }
}

func variables() -> Parser<Exp>{
    return identifier() >>= { name in
        pure(Exp.Var(name))
    }
}

func factor()->Parser<Exp>{
    return variables() +++ number() +++ (symbol("(") >>= { c in
        expr() >>= { n in
            symbol(")") >>= { _ in
                pure(n)
            }
        }
    })
}

func oper()->Parser<Character>{
    return ["=","+","-","*","/"].map({ (x:String) -> Parser<Character> in
        parserChar(x.characters[x.characters.startIndex])
    }).reduce(mzero()) { (x, y) -> Parser<Character> in
        x +++ y
    }
}

func op()->Parser<String>{
    return many1(oper()) >>= { xs in
        return pure(String(xs))
    }
}

infix operator >=< {associativity left precedence 130}

func >=<<a>(p : Parser<a>, op : Parser<(a,a) -> a>) -> Parser<a>{
    return p >>= { x in
        rest(p, x: x, op: op)
    }
}

func rest<a>(p : Parser<a>, x : a, op : Parser<(a,a) -> a>) -> Parser<a>{
    return op >>= { f in
        p >>= { y in
            rest(p, x: f(x,y), op: op)
        }
    } +++ pure(x)
}

func addop() -> Parser<(Exp,Exp)->Exp>{
    return symbol("+") >>= { _ in
        pure({(x,y) -> Exp in
            Exp.Add(x, y)
        })
    }
}

func mulop() -> Parser<(Exp,Exp) -> Exp>{
    return symbol("*") >>= { _ in
        pure({ (x,y) -> Exp in
            Exp.Times(x, y)
        })

    }
}

func relop() -> Parser<(Exp,Exp) -> Exp>{
    return symbol("<") >>= { _ in
        pure({(x,y) -> Exp in
            Exp.Less(x, y)
        })
    }
}

func expr() -> Parser<Exp>{
    return term() >=< addop()
}

func rexp() -> Parser<Exp>{
    return expr() >=< relop()
}

func term() -> Parser<Exp>{
    return factor() >=< mulop()
}


//MARK: handle statement

func assign() -> Parser<Com>{
    return identifier() >>= { name in
        symbol("=") >>= { _ in
            expr() >>= { exp in
                pure(Com.Assign(name, exp))
            }
        }
    }
}

func com() -> Parser<Com>{
    return seq() +++ com1()
}

func com1() -> Parser<Com>{
    return assign() +++ whileloop() +++ print()
}


func whileloop() -> Parser<Com>{
    return symbol("while") >>= { _ in
        rexp() >>= { cond in
            symbol("{") >>= { _ in
                com() >>= { stmt in
                    symbol("}") >>= { _ in
                        pure(Com.While(cond, stmt))
                    }
                }
            }
        }
    }
}


func print() -> Parser<Com>{
    return symbol("print") >>= { _ in
        expr() >>= { exp in
            pure(Com.Print(exp))
        }
    }
}

func seq() -> Parser<Com>{
    return com1() >>= { stmt in
        com() >>= { stmt2 in
            pure(Com.Seq(stmt, stmt2))
        }
    }
}