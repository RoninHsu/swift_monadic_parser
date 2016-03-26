//
//  main.swift
//  ParserCombinator
//
//  Created by wenjin on 3/16/16.
//  Copyright © 2016 wenjin. All rights reserved.
//

import Foundation



print("Hello, World!")

let a:String = "a"
let b: String = "    12345 + 42 * 5+(12 + 4)   abcergebac"
let c: String = " i = 0 print i sum = 0 while i<100  {sum=sum+i i=i+1 }   print sum"
let d : String = "dd= 12*3 * (12+1) print dd"

let ast = (space() >>= {_ in com()}).p(c)[0].0
interpreter(ast)



