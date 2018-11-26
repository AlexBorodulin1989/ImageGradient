//
//  IGRuntimeError.swift
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 26/11/2018.
//

struct RuntimeError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var localizedDescription: String {
        return message
    }
}
