#!/usr/bin/swift
import AppKit
import SwiftUI

@MainActor
struct AppIconArtwork: View {
    private let orange = Color(red: 1.0, green: 0.46, blue: 0.10)
    private let size: CGFloat = 1024

    var body: some View {
        ZStack {
            Color.black
            ZStack {
                Text("B")
                    .font(.system(size: size * 0.56, weight: .black, design: .rounded))
                    .foregroundStyle(orange)
                    .offset(x: -size * 0.02)
                biteNotches
            }
            .shadow(color: orange.opacity(0.35), radius: size * 0.04)
        }
        .frame(width: size, height: size)
    }

    private var biteNotches: some View {
        let notch = size * 0.11
        return ZStack {
            Circle().fill(Color.black).frame(width: notch, height: notch)
                .offset(x: size * 0.19, y: -size * 0.13)
            Circle().fill(Color.black).frame(width: notch * 0.96, height: notch * 0.96)
                .offset(x: size * 0.235, y: -size * 0.025)
            Circle().fill(Color.black).frame(width: notch * 0.92, height: notch * 0.92)
                .offset(x: size * 0.19, y: size * 0.075)
        }
    }
}

@MainActor
func renderIcon(to output: String) throws {
    let renderer = ImageRenderer(content: AppIconArtwork())
    renderer.scale = 1.0
    guard let cgImage = renderer.cgImage else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Render failed"])
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let data = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
        throw NSError(domain: "AppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Encode failed"])
    }
    try data.write(to: URL(fileURLWithPath: output))
}

let output = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.appiconset/icon-1024.png"

Task { @MainActor in
    do {
        try renderIcon(to: output)
        print("Wrote \(output)")
        exit(0)
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }
}
dispatchMain()
