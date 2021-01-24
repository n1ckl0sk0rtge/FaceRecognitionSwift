//
//  L2Norm.swift
//  Travellout
//
//  Created by Nicklas Körtge on 26.07.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation

class L2Norm {
    
    static func calculate(arr: [[Float32]]) -> [[Float32]]{
        let _arr = arr[0]
        
        var sumOfAllElements : Float32 = 0
        for i in _arr {
            sumOfAllElements += powf(i,2)
        }
        
        let divider = sqrtf(sumOfAllElements)
        
        var l2_arr = [Float32]()
        for j in _arr {
            l2_arr.append(j / divider)
        }
        
        return [l2_arr]
        
    }
    
    static func calculate(a: Float32, b: Float32) -> Float32 {
        let sumOfAllElements : Float32 = powf(a,2) + powf(b,2)
        let distance = sqrtf(sumOfAllElements)
        return distance
        
    }
    
}

class MathFunctions {
    
    static func euclidean(a: [Float32], b: [Float32]) -> Double {
        if a.count == b.count {
            var sum : Float32 = 0.0
            for i in 0..<a.count{
                sum += powf(abs(b[i] - a[i]), 2)
            }
            let erg = Double(sqrtf(sum))
            //print(erg)
            return erg
        } else {
            print("Error: Euclide distance connot calculate for different sizes of arrays.")
            return 0.0
        }
    }
    
}
