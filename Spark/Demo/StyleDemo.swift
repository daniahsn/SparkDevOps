//
//  StyleDemo.swift
//  Spark
//
//  Created by Julius  Jung on 03.11.2025.
//

import SwiftUI
    
struct ColorSwatch: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            Text(title)
                .font(SparkFont.ui(14, weight: .regular))
                .foregroundColor(.black)
        }
        .padding(.vertical, 4)
    }
}
        
        struct IconLabel: View {
            let systemName: String
            let label: String
            
            var body: some View {
                VStack(spacing: 8) {
                    Image(systemName: systemName)
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(.brandSecondary)
                        .frame(width: 56, height: 56)
                        .background(Color.brandDominant)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(label)
                        .font(SparkFont.ui(13, weight: .regular))
                        .foregroundColor(.black)
                }
            }
        }
        
        struct StyleDemo: View {
            var body: some View {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spark")
                                .font(SparkFont.logo(40, weight: .regular))
                                .foregroundColor(.brandAccent)
                            Text("Style Demo")
                                .font(SparkFont.ui(17, weight: .regular))
                                .foregroundColor(.black)
                        }
                        
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colors")
                        .font(SparkFont.ui(20, weight: .regular)).foregroundColor(.brandAccent)
                    HStack(spacing: 16) {
                        ColorSwatch(title: "Dominant", color: .brandDominant)
                        ColorSwatch(title: "Secondary", color: .brandSecondary)
                        ColorSwatch(title: "Accent", color: .brandAccent)
                    }
                    
                }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fonts")
                                .font(SparkFont.ui(20, weight: .regular)).foregroundColor(.brandAccent)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("New York (used for app's logo)")
                                    .font(SparkFont.logo(16, weight: .regular))
                                    .foregroundColor(.black)
                                Text("SF Pro (used for headers, subheaders, body")
                                    .font(SparkFont.ui(16, weight: .regular))
                                    .foregroundColor(.black)
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icons")
                                .font(SparkFont.ui(20, weight: .regular)).foregroundColor(.brandAccent)
                            Text("Icons from SF Symbols").font(SparkFont.ui(16, weight: .regular)).foregroundColor(.black)
                            LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 20) {
                                IconLabel(systemName: "mappin.and.ellipse", label: "Location")
                                IconLabel(systemName: "cloud.sun", label: "Weather")
                                IconLabel(systemName: "face.smiling", label: "Emotion")
                                IconLabel(systemName: "house", label: "Home")
                                IconLabel(systemName: "lock", label: "Lock")
                                IconLabel(systemName: "lock.open", label: "Unlock")
                            }
    
                        }
                        Spacer(minLength: 12)
                    }
                    .padding(20)
                    .background(Color.brandDominant.ignoresSafeArea())
                }
            }
        }
        
        #Preview {
            StyleDemo()
        }

