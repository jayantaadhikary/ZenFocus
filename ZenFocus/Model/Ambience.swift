//
//  Ambience.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 11/06/25.
//

import Foundation

struct AmbientOption: Identifiable, Equatable {
    let id = UUID() // for use with ForEach
    let name: String
    let icon: String
    let audioFileName: String?
}

let ambientOptions: [AmbientOption] = [
    AmbientOption(name: "Rain", icon: "cloud.rain", audioFileName: "rain.mp3"),
    AmbientOption(name: "Forest", icon: "leaf", audioFileName: "forest.mp3"),
    AmbientOption(name: "Cafe", icon: "cup.and.saucer", audioFileName: "cafe.mp3")
]
