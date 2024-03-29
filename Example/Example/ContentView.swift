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
            Image("TruePdf")
            
            if let image = UIImage(named: "FalsePdf") {
                Image(uiImage: image)
            }

            Image("checkSVG")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
