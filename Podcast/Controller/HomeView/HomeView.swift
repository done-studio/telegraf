//
//  HomeView.swift
//  Podcast
//
//  Created by Adrian Evensen on 24/05/2020.
//  Copyright © 2020 AdrianF. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    
    @State var showRSSURLField = false
    @State var rssURL = ""
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: Podcast.entity(), sortDescriptors: []) var podcasts: FetchedResults<Podcast>
    
    var body: some View {
        NavigationView{
                List {
                    if self.showRSSURLField {
                        VStack {
                            TextField("RSS Feed...", text: self.$rssURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            HStack{
                                Button("Add") {
                                    print("add")
                                }
                                .accentColor(.green)
                                .foregroundColor(.blue)
                                Spacer()
                                Button("Cancel") {
                                    print("cancel")

                                }
                            }
                            .padding()
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    ForEach(podcasts, id: \.name) { podcast in
                        NavigationLink(destination: PlayerView(pod: podcast)) {
                            Text(podcast.name ?? "")

                        }
                    }
                }
            
                .navigationBarTitle("Podcasts", displayMode: .inline)
                .navigationBarItems(trailing: Button("Add") {
                    self.showRSSURLField = !self.showRSSURLField
                })
        }
    }
}
