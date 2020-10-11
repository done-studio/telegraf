//
//  PlayerView.swift
//  Podcast
//
//  Created by Adrian Evensen on 14/05/2020.
//  Copyright © 2020 AdrianF. All rights reserved.
//

import SwiftUI
import UIKit
import WebKit
import SafariServices

struct PodcastArtworkView: View {
    var artwork: Data?
    
    var body: some View {
        ArtworkView
    }
    
    fileprivate var ArtworkView: some View {
        if let art = self.artwork, let uiArt = UIImage(data: art) {
            return VStack{
                Image(uiImage: uiArt)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .cornerRadius(10)
            }
        } else {
            return VStack {
                Image("")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .cornerRadius(10)
            }
        }
    }
}

struct PodcastTopView: View {
    var artwork: Data?
    var name: String?
    var artist: String?
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                PodcastArtworkView(artwork: artwork)
                VStack{
                    Text(name ?? "")
                        .font(.headline)
                    Text(artist ?? "")
                        .font(.body)
                }
                Spacer()
            }
        }
    }
}


struct EpisodeRow: View {
    
    var episode: String
    
    var body: some View {
        VStack{
            Text(episode)
            
        }
        .clipped()
        .cornerRadius(10, antialiased: true)
        .listRowBackground(Color.clear)
    }
}

struct PlayerView : View {
    @State var internetEpisodes: [EpisodeDataSource] = []
    @State var isLoading = true
    
    @State var presentInternetEpisode = false
    
    var pod: Podcast
    
    var body: some View{
            List{
                PodcastTopView(artwork: pod.artwork, name: pod.name, artist: pod.artist)
                
                Section(header: Text("Local")) {
                    ForEach((pod.episodes?.allObjects ?? []) as [Episode], id: \.name) { episode in
                        EpisodeRow(episode: episode.name ?? "")
                    }
                }
                
                Section(header: Text("From The Internet")) {
                    if isLoading {
                        HStack(alignment: .center){
                            VStack(alignment: .center){
                                ActivityIndicator(isAnimating: $isLoading, style: .medium)
                            }
                        }

                    }
                    ForEach(internetEpisodes) { episode in
                        EpisodeRow(episode: episode.name ?? "")
                            .onTapGesture {
                                self.presentInternetEpisode = true
                        }
                            .sheet(isPresented: self.$presentInternetEpisode) {
                                PodcastDetailsView(episode: episode)
                        }
                        
                    }
                }

            }
        .listStyle(GroupedListStyle())
        .onAppear() {
            self.getPodcast()
        }

    }
    
//    var body: some View {
//        List{
//            PodcastTopView(picked: $picked, artwork: podcast?.artwork, name: podcast?.name, artist: podcast?.artist)
//
//            if isLoading {
//                HStack(alignment: .center) {
//                    ActivityIndicator(isAnimating: $isLoading, style: .medium)
//                }
//            } else {
//                PodcastEpisodeLister(episodes: episodes)
//            }
//            }.onAppear(perform: getPodcast)
//    }
//
    fileprivate func getPodcast() {
        guard let feed = URL(string: pod.feed ?? "") else { return }
        Episodes.shared.set(url: feed) {
            self.internetEpisodes = Episodes.shared.episodes
            self.isLoading = false
        }
    }
    
}

struct PodcastEpisodeLister: View {
    var episodes: [EpisodeDataSource] = []
    @State var persentDetails = false
    
    var body: some View {
        ForEach(episodes) { ep in
            Button(action: {
                self.persentDetails = !self.persentDetails
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(ep.name ?? "")
                            .font(.subheadline)
                            .bold()
                        Text(ep.subtitle ?? "")
                            .font(.caption)
                    }
                    Spacer()
                }
                }
            .sheet(isPresented: self.$persentDetails) {
                PodcastDetailsView(episode: ep)
            }
        }
    }
}



struct PodcastDetailsView: View {
    var episode: EpisodeDataSource
    @State var persentDetailsLink = false
    
    var player = AVPlayer()
    
    @State var epURL: URL? = nil
    
    var body: some View {
        VStack{
            Text(episode.name ?? "")
                .fontWeight(.bold)
            HStack{
                Button(action: {
                    guard let url = URL(string: self.episode.episodeUrl ?? "") else { return }
                    Player.shared.play(ep: self.episode)
                }) {
                    Text("Spill Episode")
                }
            }
            
            WebView(url: episode.description ?? "-", present: { url in
                self.epURL = url
                self.persentDetailsLink = true
            })
            
        }
        .padding()
        .sheet(isPresented: $persentDetailsLink, content: {
                SafariiiView(URL: self.epURL!)
            })
    }
}

struct SafariiiView: UIViewControllerRepresentable {
    let URL: URL
    
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let sfvc = SFSafariViewController(url: URL)
        return sfvc
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = SFSafariViewController
    
    
    
    
    
}
