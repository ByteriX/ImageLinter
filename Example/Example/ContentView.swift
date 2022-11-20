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
            images1()
        }
        .padding()
    }
    
    @ViewBuilder
    func images1() -> some View {
        Image("TruePng")
            .imageScale(.large)
            .foregroundColor(.accentColor)
        Image("TruePng")
        Image("TruePdf")
        Image("FalsePdf")
        Image("Duplicate")
        
        if let image = UIImage(named: "NotDuplicated") {
            Image(uiImage: image)
        }
        
        Image("NotFoundImage")
    }
    
    @ViewBuilder
    func images2() -> some View {
        
        Image("MixedUp1")
        Image("MixedUp2")
        Image("MixedUp3")
        Image("BadRaster")
        
        Image("DuplicatedImage1")
        Image("DuplicatedImage2")
        Image("Folder/DuplicatedImage3")
        Image("DuplicatedImage4")
        Image("NotFoundFile")
    }
    
    @ViewBuilder
    func images3() -> some View {
        Image("BigRastor")
        Image("BigVector")
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
