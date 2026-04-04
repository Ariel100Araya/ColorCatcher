//
//  ContentView.swift
//  ColorCatcher
//
//  Created by Ariel Araya-Madrigal on 4/4/26.
//

import SwiftUI
import AppKit
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ContentView: View {
    @State private var red: Double = 255
    @State private var green: Double = 99
    @State private var blue: Double = 71
    @State private var aiSummary = "Generate a recommendation to get a quick pairing note for your current color."
    @State private var modelStatus = ColorRecommendationAI.defaultStatus
    @State private var isGeneratingRecommendation = false
    @State private var isPinned = false
    @State private var isMiniMode = true
    @State private var window: NSWindow?
    @State private var colorPanelObserver: NSObjectProtocol?

    private var selectedColor: Color {
        Color(
            red: red / 255,
            green: green / 255,
            blue: blue / 255
        )
    }

    private var selectedNSColor: NSColor {
        NSColor(
            srgbRed: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: 1
        )
    }

    private var hexValue: String {
        Self.hexString(red: Int(red.rounded()), green: Int(green.rounded()), blue: Int(blue.rounded()))
    }

    private var rgbValue: String {
        "\(Int(red.rounded())), \(Int(green.rounded())), \(Int(blue.rounded()))"
    }

    private var recommendations: [ColorRecommendation] {
        ColorPaletteEngine.recommendations(for: selectedNSColor)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 0.95),
                    Color(red: 0.85, green: 0.91, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                if isMiniMode {
                    miniMeter
                } else {
                    VStack(spacing: 24) {
                        ScrollView {
                            VStack(spacing: 24) {
                                header
                                meterCard
                                suggestionsCard
                                aiCard
                            }
                        }
                    }
                    .padding(28)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    windowControls
                }
                Spacer()
            }
            .padding(18)
        }
        .background(WindowReader { newWindow in
            window = newWindow
            configureWindow()
        })
        .frame(
            minWidth: isMiniMode ? 220 : 520,
            idealWidth: isMiniMode ? 240 : 520,
            minHeight: isMiniMode ? 250 : 450,
            idealHeight: isMiniMode ? 250 : 450
        )
        .onAppear {
            modelStatus = ColorRecommendationAI.statusMessage
            configureWindow()
        }
        .onChange(of: hexValue) { _ in
            aiSummary = "Generate a recommendation to get a quick pairing note for your current color."
        }
        .onChange(of: isPinned) { _ in
            configureWindow()
        }
        .onChange(of: isMiniMode) { _ in
            configureWindow()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ColorCatcher")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Catch a color, inspect its Hex and RGB values, and generate matching accents.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var windowControls: some View {
        HStack(spacing: 10) {
            if #available(macOS 26.0, *) {
                Button {
                    isMiniMode.toggle()
                } label: {
                    Label(
                        isMiniMode ? "Expand" : "Mini",
                        systemImage: isMiniMode ? "arrow.down.right.and.arrow.up.left" : "circle.dashed.inset.filled"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .glassEffect()
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .help(isMiniMode ? "Expand the utility" : "Collapse into a small utility view")
            } else {
                // Fallback on earlier versions
                Button {
                    isMiniMode.toggle()
                } label: {
                    Label(
                        isMiniMode ? "Expand" : "Mini",
                        systemImage: isMiniMode ? "arrow.down.right.and.arrow.up.left" : "circle.dashed.inset.filled"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .help(isMiniMode ? "Expand the utility" : "Collapse into a small utility view")
            }

            if #available(macOS 26.0, *) {
                Button {
                    isPinned.toggle()
                } label: {
                    Label(
                        isPinned ? "Pinned" : "Pin",
                        systemImage: isPinned ? "pin.fill" : "pin"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .glassEffect()
                .background {
                    Circle()
                        .fill(isPinned ? AnyShapeStyle(Color.white.opacity(0.85)) : AnyShapeStyle(.ultraThinMaterial))
                }
                .help(isPinned ? "Keep this window above other windows" : "Pin this window on top")
            } else {
                // Fallback on earlier versions
                Button {
                    isPinned.toggle()
                } label: {
                    Label(
                        isPinned ? "Pinned" : "Pin",
                        systemImage: isPinned ? "pin.fill" : "pin"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .background {
                    Circle()
                        .fill(isPinned ? AnyShapeStyle(Color.white.opacity(0.85)) : AnyShapeStyle(.ultraThinMaterial))
                }
                .help(isPinned ? "Keep this window above other windows" : "Pin this window on top")
            }
        }
    }

    private var miniMeter: some View {
        VStack(spacing: 14) {
            Button {
                openSystemColorPanel()
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedColor)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.7), lineWidth: 2)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 8)

                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                }
                .frame(width: 58, height: 58)
            }
            .buttonStyle(.plain)
            .help("Open the system color picker")

            Text(hexValue)
                .font(.system(size: 20, weight: .bold, design: .monospaced))

            Text("RGB \(rgbValue)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)

            Text("Click the color to pick a new one")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Button("Copy Hex") {
                copyToPasteboard(hexValue)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var meterCard: some View {
        VStack(spacing: 24) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                selectedColor.opacity(0.95),
                                selectedColor.opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
                    }
                    .shadow(color: .black.opacity(0.10), radius: 18, y: 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Sample")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(hexValue)
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text("RGB \(rgbValue)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.88))
                }
                .padding(24)
            }
            .frame(height: 220)

            HStack(spacing: 16) {
                ColorPicker(
                    "Pick a Color",
                    selection: Binding(
                        get: { selectedColor },
                        set: updateColorComponents(from:)
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()

                Text("Pick a color")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                Spacer()

                Button("Copy Hex") {
                    copyToPasteboard(hexValue)
                }
                .buttonStyle(.borderedProminent)

                Button("Copy RGB") {
                    copyToPasteboard(rgbValue)
                }
                .buttonStyle(.bordered)
            }

            VStack(spacing: 18) {
                ColorChannelRow(name: "Red", tint: .red, value: $red)
                ColorChannelRow(name: "Green", tint: .green, value: $green)
                ColorChannelRow(name: "Blue", tint: .blue, value: $blue)
            }

            HStack(spacing: 14) {
                ValueCard(title: "HEX", value: hexValue)
                ValueCard(title: "RGB", value: rgbValue)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Recommended Matches")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("These pairings are generated from color harmony rules.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            ForEach(recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation, onCopy: copyToPasteboard)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Apple Intelligence Notes")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text(modelStatus)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(isGeneratingRecommendation ? "Generating..." : "Generate Recommendation") {
                    Task {
                        await generateAISummary()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGeneratingRecommendation)
            }

            Text(aiSummary)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private func generateAISummary() async {
        isGeneratingRecommendation = true
        defer { isGeneratingRecommendation = false }

        let response = await ColorRecommendationAI.summarize(
            baseHex: hexValue,
            baseRGB: rgbValue,
            recommendations: recommendations
        )

        aiSummary = response.summary
        modelStatus = response.status
    }

    private func updateColorComponents(from color: Color) {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else {
            return
        }

        red = srgb.redComponent * 255
        green = srgb.greenComponent * 255
        blue = srgb.blueComponent * 255
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func openSystemColorPanel() {
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.color = selectedNSColor

        if let colorPanelObserver {
            NotificationCenter.default.removeObserver(colorPanelObserver)
        }

        colorPanelObserver = NotificationCenter.default.addObserver(
            forName: NSColorPanel.colorDidChangeNotification,
            object: panel,
            queue: .main
        ) { _ in
            updateColorComponents(from: Color(panel.color))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow() {
        guard let window else {
            return
        }

        window.level = isPinned ? .floating : .normal
        window.collectionBehavior = isPinned ? [.fullScreenAuxiliary, .moveToActiveSpace] : []
        window.isMovableByWindowBackground = true
        window.titleVisibility = isMiniMode ? .hidden : .visible
        window.titlebarAppearsTransparent = true

        let targetSize = isMiniMode
            ? NSSize(width: 270, height: 160)
            : NSSize(width: 520, height: 450)

        if window.frame.size != targetSize {
            window.setContentSize(targetSize)
        }
    }

    private static func hexString(red: Int, green: Int, blue: Int) -> String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }
}

private struct ColorChannelRow: View {
    let name: String
    let tint: Color
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 14) {
            Text(name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(width: 60, alignment: .leading)

            Slider(value: $value, in: 0...255, step: 1)
                .tint(tint)

            Text("\(Int(value.rounded()))")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private struct ValueCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct RecommendationCard: View {
    let recommendation: ColorRecommendation
    let onCopy: (String) -> Void

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(recommendation.color)
                .frame(width: 96, height: 96)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Spacer()

                    Button("Copy \(recommendation.hex)") {
                        onCopy(recommendation.hex)
                    }
                    .buttonStyle(.bordered)
                }

                Text(recommendation.role)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(recommendation.description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label(recommendation.hex, systemImage: "number.square")
                    Label(recommendation.rgb, systemImage: "slider.horizontal.3")
                }
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct ColorRecommendation: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let role: String
    let description: String
    let color: Color
    let hex: String
    let rgb: String
}

private enum ColorPaletteEngine {
    static func recommendations(for color: NSColor) -> [ColorRecommendation] {
        let base = swatch(from: color)
        let hueOffsets: [(String, String, Double, Double, Double)] = [
            ("Contrast Pop", "Complementary", 0.50, 0.96, 0.98),
            ("Warm Wing", "Analogous", -0.08, 0.90, 1.04),
            ("Cool Wing", "Analogous", 0.08, 0.92, 0.94)
        ]

        return hueOffsets.map { title, role, offset, saturationScale, brightnessScale in
            let adjusted = makeSwatch(
                hue: wrap(base.hue + offset),
                saturation: clamp(base.saturation * saturationScale, min: 0.18, max: 0.92),
                brightness: clamp(base.brightness * brightnessScale, min: 0.30, max: 0.98)
            )

            let copy = title == "Contrast Pop"
                ? "High-energy opposite tone that helps buttons, focus states, or key labels stand out."
                : "Neighboring hue that keeps the palette cohesive while adding depth around the base color."

            return ColorRecommendation(
                title: title,
                role: role,
                description: copy,
                color: adjusted.color,
                hex: adjusted.hex,
                rgb: adjusted.rgb
            )
        }
    }

    private static func swatch(from color: NSColor) -> ColorSwatch {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        srgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let red = Int((srgb.redComponent * 255).rounded())
        let green = Int((srgb.greenComponent * 255).rounded())
        let blue = Int((srgb.blueComponent * 255).rounded())

        return ColorSwatch(
            hue: hue,
            saturation: saturation,
            brightness: brightness,
            red: red,
            green: green,
            blue: blue
        )
    }

    private static func makeSwatch(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> ColorSwatch {
        let color = NSColor(calibratedHue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        return swatch(from: color)
    }

    private static func wrap(_ value: CGFloat) -> CGFloat {
        let result = value.truncatingRemainder(dividingBy: 1)
        return result >= 0 ? result : result + 1
    }

    private static func clamp(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, lower), upper)
    }
}

private struct ColorSwatch {
    let hue: CGFloat
    let saturation: CGFloat
    let brightness: CGFloat
    let red: Int
    let green: Int
    let blue: Int

    var color: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    var hex: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    var rgb: String {
        "\(red), \(green), \(blue)"
    }
}

private enum ColorRecommendationAI {
    static let defaultStatus = "On-device guidance can add context about where the palette works best."

    static var statusMessage: String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                return "Apple Intelligence is available for palette notes on this Mac."
            case .unavailable(.deviceNotEligible):
                return "Apple Intelligence is unavailable because this Mac is not eligible."
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence is installed, but it is not enabled yet."
            case .unavailable(.modelNotReady):
                return "Apple Intelligence exists here, but the local model is still getting ready."
            @unknown default:
                return defaultStatus
            }
        } else {
            return "FoundationModels requires macOS 26 or later."
        }
        #else
        return "FoundationModels is not available in this build environment."
        #endif
    }

    static func summarize(baseHex: String, baseRGB: String, recommendations: [ColorRecommendation]) async -> (summary: String, status: String) {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default

            guard model.isAvailable else {
                return (fallbackSummary(baseHex: baseHex, recommendations: recommendations), statusMessage)
            }

            let paletteLines = recommendations.enumerated().map { index, item in
                "\(index + 1). \(item.title) (\(item.role)) - \(item.hex), RGB \(item.rgb)"
            }.joined(separator: "\n")

            let prompt = """
            You are helping inside a macOS color meter app.
            Base color: \(baseHex)
            Base RGB: \(baseRGB)

            Suggested pairings:
            \(paletteLines)

            Write exactly three concise sentences. Explain what mood this palette creates and mention practical UI or branding uses for the suggested colors.
            """

            do {
                let session = LanguageModelSession(
                    model: model,
                    instructions: "Be practical, concise, and specific. Do not use bullet points."
                )
                let response = try await session.respond(
                    to: prompt,
                    options: GenerationOptions(temperature: 0.7, maximumResponseTokens: 140)
                )
                return (response.content.trimmingCharacters(in: .whitespacesAndNewlines), statusMessage)
            } catch {
                return (fallbackSummary(baseHex: baseHex, recommendations: recommendations), "Apple Intelligence hit an error, so the app fell back to built-in guidance.")
            }
        } else {
            return (fallbackSummary(baseHex: baseHex, recommendations: recommendations), statusMessage)
        }
        #else
        return (fallbackSummary(baseHex: baseHex, recommendations: recommendations), statusMessage)
        #endif
    }

    private static func fallbackSummary(baseHex: String, recommendations: [ColorRecommendation]) -> String {
        guard recommendations.count >= 3 else {
            return "The current color \(baseHex) works best with one contrasting accent and a couple of neighboring support tones."
        }

        return "\(baseHex) stays as the anchor, \(recommendations[0].hex) gives you the strongest contrast for calls to action, and \(recommendations[1].hex) plus \(recommendations[2].hex) keep the rest of the interface cohesive. Use the contrast color sparingly for emphasis, then let the analogous colors handle backgrounds, highlights, and secondary surfaces."
    }
}

private struct WindowReader: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            onResolve(view.window)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onResolve(nsView.window)
        }
    }
}

#Preview {
    ContentView()
}
