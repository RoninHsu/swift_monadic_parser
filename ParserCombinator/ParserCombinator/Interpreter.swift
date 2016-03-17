//
//  Interpreter.swift
//  ParserCombinator
//
//  Created by aaaron7 on 16/3/17.
//  Copyright © 2016年 wenjin. All rights reserved.
//

import Foundation

var varTable : [String:Int] = [:]

func getvar(name : String) -> Int{
    return varTable[name]!
}

func eval(exp : Exp) -> Int{
    switch exp{
    case let Exp.Constant(x):
        return x
    case let Exp.Var(name):
        return getvar(name)
    case let Exp.Add(exp1, exp2):
        return eval(exp1) + eval(exp2)
    case let Exp.Less(exp1, exp2):
        let a = eval(exp1)
        let b = eval(exp2)
        if a > b {
            return 0
        }else{
            return 1
        }
    case let Exp.Times(exp1, exp2):
        return eval(exp1) + eval(exp2)
    default:
        return 0
    }
}

func interpreter(stmt : Com) {

    func loopHelper(cond : Exp,st : Com){
        if eval(cond) == 0{
            return
        }else{
            interpreter(st)
            loopHelper(cond, st: st)
        }
    }

    switch stmt{
    case let Com.Assign(name, exp1):
        varTable[name] = eval(exp1)
    case let Com.Seq(st1, st2):
        interpreter(st1)
        interpreter(st2)
    case let Com.While(cond, st1):
        loopHelper(cond, st: st1)
    case let Com.Print(exp):
        print(eval(exp))
    default:
        return
    }
}