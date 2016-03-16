//
//  Syntax.swift
//  ParserCombinator
//
//  Created by aaaron7 on 16/3/16.
//  Copyright © 2016年 wenjin. All rights reserved.
//

import Foundation



indirect enum Exp{
    case Constant (Int)
    case Var (String)
    case Add (Exp,Exp)
    case Equal (Exp,Exp)


    var pConstant : Int {
        switch self{
        case let .Constant(x):
            return x
        default:
            return 0
        }
    }
}

indirect enum Com{
    case Assign (String,Exp)
    case Seq (Com,Com)
    case Cond (Exp,Com,Com)
    case For (String,Exp,Exp,Exp,Com)
}