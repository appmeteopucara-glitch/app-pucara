import AppKit
import CoreGraphics
import Foundation

// A partir de noviembre 2026 el ícono de la app es una imagen ya completa
// (fondo, montañas, íconos de clima y el texto "PUCARÁ" integrados), no el
// símbolo suelto compuesto sobre un fondo generado por código. Por eso este
// script solo redimensiona assets/images/app_icon_source.png a cada tamaño,
// sin dibujar fondo ni glow adicionales.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = root.appendingPathComponent("assets/images/app_icon_source.png")

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
  fputs("No se pudo abrir assets/images/app_icon_source.png\n", stderr)
  exit(1)
}

guard let sourceCGImage = sourceImage.cgImage(
  forProposedRect: nil,
  context: nil,
  hints: nil
) else {
  fputs("No se pudo convertir el ícono a CGImage\n", stderr)
  exit(1)
}

func drawIcon(side: Int, outputURL: URL) throws {
  guard let context = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
  ) else {
    throw NSError(domain: "icon-generator", code: 1)
  }

  let canvasRect = CGRect(x: 0, y: 0, width: side, height: side)
  context.interpolationQuality = .high
  context.draw(sourceCGImage, in: canvasRect)

  guard let finalImage = context.makeImage() else {
    throw NSError(domain: "icon-generator", code: 2)
  }
  let rep = NSBitmapImageRep(cgImage: finalImage)
  guard let data = rep.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "icon-generator", code: 3)
  }
  try data.write(to: outputURL)
}

let androidTargets: [(path: String, size: Int)] = [
  ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48),
  ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72),
  ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96),
  ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144),
  ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192),
]

for target in androidTargets {
  try drawIcon(side: target.size, outputURL: root.appendingPathComponent(target.path))
}

let contentsURL = root.appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json")
let contentsData = try Data(contentsOf: contentsURL)
let json = try JSONSerialization.jsonObject(with: contentsData) as! [String: Any]
let images = json["images"] as! [[String: Any]]

for image in images {
  guard let filename = image["filename"] as? String,
        let sizeText = image["size"] as? String,
        let scaleText = image["scale"] as? String,
        let baseSize = Double(sizeText.components(separatedBy: "x").first ?? ""),
        let scale = Double(scaleText.replacingOccurrences(of: "x", with: "")) else {
    continue
  }

  let pixels = Int(round(baseSize * scale))
  let outputURL = root.appendingPathComponent("ios/Runner/Assets.xcassets/AppIcon.appiconset/\(filename)")
  try drawIcon(side: pixels, outputURL: outputURL)
}

print("Iconos generados correctamente")
