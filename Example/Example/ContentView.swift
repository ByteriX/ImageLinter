//
//  ContentView.swift
//  Example
//
//  Created by Sergey Balalaev on 27.09.2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("TruePng")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Image("TruePng")
            Image("TruePdf")
            Image("FalsePdf")
            Image("Doublicate")
            
            if let image = UIImage(named: "NotDoublicated") {
                Image(uiImage: image)
            }
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
