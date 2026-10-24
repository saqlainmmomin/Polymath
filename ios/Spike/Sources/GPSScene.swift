import SwiftUI
import RealityKit
import UIKit
import Combine

// MARK: - helpers

private func lit(_ hex: UInt32, rough: Float = 0.9, metal: Bool = false) -> SimpleMaterial {
    SimpleMaterial(color: UIColor(hex: hex), roughness: .init(floatLiteral: rough), isMetallic: metal)
}
private func glow(_ hex: UInt32, culling: Bool = true) -> UnlitMaterial {
    var m = UnlitMaterial(color: UIColor(hex: hex)); m.faceCulling = culling ? .back : .none; return m
}
private func model(_ mesh: MeshResource, _ mat: any RealityKit.Material, at p: SIMD3<Float> = .zero) -> ModelEntity {
    let e = ModelEntity(mesh: mesh, materials: [mat]); e.position = p; return e
}
private func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float { let t = min(max((x - a) / (b - a), 0), 1); return t * t * (3 - 2 * t) }
private func ramp(_ x: Float, _ a: Float, _ b: Float) -> Float { min(max((x - a) / (b - a), 0), 1) }
private func setOpacity(_ e: Entity, _ o: Float) { e.components.set(OpacityComponent(opacity: max(0, min(1, o)))) }

/// A rounded limb: cylinder between two points with sphere end caps (a capsule).
private func limb(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ r: Float, _ mat: SimpleMaterial) -> Entity {
    let e = Entity(), d = b - a, len = simd_length(d)
    let cyl = model(.generateCylinder(height: len, radius: r), mat, at: (a + b) / 2)
    cyl.orientation = simd_quatf(from: [0, 1, 0], to: d / len)
    e.addChild(cyl); e.addChild(model(.generateSphere(radius: r), mat, at: a)); e.addChild(model(.generateSphere(radius: r), mat, at: b))
    return e
}

/// Soft radial glow texture (white, alpha falling off), tinted per use.
private func glowTexture() -> TextureResource? {
    let n = 128
    guard let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
          let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: [UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0.18).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray,
                             locations: [0, 0.22, 1]) else { return nil }
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: n / 2, y: n / 2), startRadius: 0, endCenter: CGPoint(x: n / 2, y: n / 2), endRadius: CGFloat(n / 2), options: [])
    guard let img = ctx.makeImage() else { return nil }
    return try? TextureResource(image: img, options: .init(semantic: .color))
}

// MARK: - Earth texture (generated once, off the main thread, shared by every card)

private func hash(_ x: Int, _ y: Int, _ z: Int) -> Float {
    var h = UInt32(truncatingIfNeeded: x &* 374761393 &+ y &* 668265263 &+ z &* 2147483647)
    h = (h ^ (h >> 13)) &* 1274126177
    return Float((h ^ (h >> 16)) & 0xFFFF) / 65535
}
private func vnoise(_ p: SIMD3<Float>) -> Float {
    let i = SIMD3<Int>(Int(floor(p.x)), Int(floor(p.y)), Int(floor(p.z)))
    let f = p - SIMD3<Float>(floor(p.x), floor(p.y), floor(p.z))
    let u = f * f * (3 - 2 * f)
    func h(_ a: Int, _ b: Int, _ c: Int) -> Float { hash(i.x + a, i.y + b, i.z + c) }
    let x00 = h(0,0,0) + (h(1,0,0) - h(0,0,0)) * u.x, x10 = h(0,1,0) + (h(1,1,0) - h(0,1,0)) * u.x
    let x01 = h(0,0,1) + (h(1,0,1) - h(0,0,1)) * u.x, x11 = h(0,1,1) + (h(1,1,1) - h(0,1,1)) * u.x
    let y0 = x00 + (x10 - x00) * u.y, y1 = x01 + (x11 - x01) * u.y
    return y0 + (y1 - y0) * u.z
}

enum EarthAssets {
    /// Computed on background threads the first time any card asks; later cards reuse it.
    static let image = Task.detached(priority: .userInitiated) { () -> CGImage in
        let W = 1024, H = 512
        var px = [UInt8](repeating: 255, count: W * H * 4)
        let home = SIMD3<Float>(0, 0, 1)
        px.withUnsafeMutableBufferPointer { buf in
            let base = buf.baseAddress!
            DispatchQueue.concurrentPerform(iterations: H) { y in
                for x in 0..<W {
                    let lon = 2 * Float.pi * Float(x) / Float(W), lat = Float.pi * (0.5 - Float(y) / Float(H))
                    let d = SIMD3<Float>(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))
                    var n: Float = 0, amp: Float = 0.5, f: Float = 2.2
                    for _ in 0..<4 { n += vnoise(d * f + 7) * amp; amp *= 0.5; f *= 2.1 }
                    let near = max(smooth(0.9, 0.2, simd_length(d - home)), smooth(0.9, 0.2, simd_length(d + home)))
                    n += near * 0.7
                    let c: UInt32
                    if n > 0.78 { c = 0x3f8a52 } else if n > 0.58 { c = 0x58a860 } else if n > 0.53 { c = 0xe3cf8f }
                    else if n > 0.43 { c = 0x2f8fd0 } else { c = 0x1b5fa8 }
                    let o = (y * W + x) * 4
                    base[o] = UInt8((c >> 16) & 255); base[o+1] = UInt8((c >> 8) & 255); base[o+2] = UInt8(c & 255)
                }
            }
        }
        return CGContext(data: &px, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: CGColorSpaceCreateDeviceRGB(),
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
    }
    @MainActor static var texture: TextureResource?
    @MainActor static var glowTex: TextureResource?
    @MainActor static func loadTexture() async -> TextureResource? {
        if let t = texture { return t }
        let cg = await image.value
        texture = try? await TextureResource(image: cg, options: .init(semantic: .color))
        return texture
    }
}

struct SceneLabel: Identifiable, Equatable {
    let id: String
    var text: String
    var x: CGFloat = 0, y: CGFloat = 0, dx: CGFloat = 0, dy: CGFloat = 0
    var opacity: Double = 0
    var you = false
}

// MARK: - scene

@MainActor
final class GPSScene: ObservableObject {
    /// 0 broadcast, 1 delay, 2 two circles, 3 three circles and the pin.
    let mode: Int
    @Published var labels: [SceneLabel] = []
    @Published var clock: (text: String, opacity: Double)?
    var aspect: Float = 0.7

    private let R: Float = 5
    private var C: SIMD3<Float> { [0, -R, 0] }
    private var t: Float = 0, now: Float = 0
    private var running = false, reduce = false
    private var sub: EventSubscription?
    private let restTime: [Float] = [4.5, 7, 8, 9.5]

    private let camera = PerspectiveCamera()
    private var camPos: SIMD3<Float> = [0, 3.3, 11.5], camTarget: SIMD3<Float> = [0, 3, 0]
    private let fov: Float = 48

    private let local = Entity(), sat = Entity()
    private var beacon: ModelEntity!
    private var satLight: Entity!
    private var phoneGlow: Entity!
    private var main: BeamRig!, side: [BeamRig] = []
    private var rings: [ModelEntity] = []
    private var sparks: [(e: ModelEntity, t: Float, a: Float, r: Float)] = []
    private var stars: [(e: ModelEntity, ph: Float)] = []
    private var groundRing: ModelEntity!
    private var phoneSprite: ModelEntity!, satSprite: ModelEntity!
    private var earthModel: ModelEntity?
    private let houses: [(Float, Float)] = [(-1.7, -0.5), (1.7, -0.4), (3.2, -1.4), (-3.2, -1.6)]
    private let phoneW: SIMD3<Float> = [0.47, 1.22, 0]
    private var glowMat: [UInt32: UnlitMaterial] = [:]

    // mode 1
    private var pulse = Entity(), pulseGlow: ModelEntity!, trail: [ModelEntity] = [], dimParts: [ModelEntity] = []
    // modes 2, 3
    private struct Tri { var psi: Float; var phi: Float; var col: UInt32; var s = SIMD3<Float>.zero; var sat = Entity(); var dots: [ModelEntity] = []; var line = ModelEntity(); var beacon: ModelEntity! }
    private var tri: [Tri] = []
    private var markYou: ModelEntity!, markMirror: ModelEntity!, pin = Entity()
    private var pinFlat: ModelEntity!
    private let P: SIMD3<Float> = [0, 1, 0]
    private var mirror: SIMD3<Float> = [0, 1, 0]
    private let SEG = 120
    private var shown: [Int] = [0, 0, 0]
    private var starsTop = Entity()

    private final class BeamRig {
        let root = Entity(); var layers: [ModelEntity] = []; let weights: [Float]
        init(mesh: MeshResource, color: UInt32, widths: [Float], weights: [Float], parent: Entity) {
            self.weights = weights
            for w in widths {
                let m = ModelEntity(mesh: mesh, materials: [glow(color, culling: false)]); m.scale = [w, 1, w]; root.addChild(m); layers.append(m)
            }
            parent.addChild(root)
        }
        func set(_ o: Float) { for (l, w) in zip(layers, weights) { setOpacity(l, o * w) }; root.isEnabled = o > 0.002 }
        func aim(from a: SIMD3<Float>, to b: SIMD3<Float>, radius: Float) {
            let d = b - a, len = simd_length(d)
            root.position = a + d / 2
            root.orientation = simd_quatf(from: [0, 1, 0], to: -d / len)   // apex (+y) at the satellite
            root.scale = [radius, len, radius]
        }
    }

    init(mode: Int) { self.mode = mode }

    func setActive(_ active: Bool, reduce r: Bool) {
        reduce = r
        if r { running = false; t = restTime[mode]; update(0); return }
        if active && !running { t = 0 }
        running = active
        if !active { update(0) }
    }

    private func dirAt(_ dx: Float, _ dz: Float) -> SIMD3<Float> { simd_normalize([dx / R, 1, dz / R]) }
    private func stand(_ e: Entity, _ dx: Float, _ dz: Float, spin: Float = 0) {
        let d = dirAt(dx, dz)
        e.position = C + d * R
        e.orientation = simd_quatf(from: [0, 1, 0], to: d) * simd_quatf(angle: spin, axis: [0, 1, 0])
        local.addChild(e)
    }

    func build(_ content: RealityViewCameraContent) async {
        var content = content
        content.camera = .virtual
        camera.camera.fieldOfViewInDegrees = fov
        content.add(camera)

        let sun = DirectionalLight()
        sun.light.intensity = 2600; sun.light.color = UIColor(hex: 0xfff0d6)
        sun.look(at: .zero, from: [-4, 6, 8], relativeTo: nil)
        content.add(sun)
        let fill = DirectionalLight()
        fill.light.intensity = 450; fill.light.color = UIColor(hex: 0x6f8cff)
        fill.look(at: .zero, from: [5, 2, 4], relativeTo: nil)
        content.add(fill)

        if EarthAssets.glowTex == nil { EarthAssets.glowTex = glowTexture() }
        let earth = makeEarth()
        content.add(earth)
        content.add(local); buildScenery()
        buildSatellite(); content.add(sat)
        buildBeams(content)
        buildStars(content)
        if mode == 1 { buildDelay(content) }
        if mode >= 2 { buildTriangulation(content) }
        built = true
        sub = content.subscribe(to: SceneEvents.Update.self) { [weak self] ev in
            guard let self else { return }
            MainActor.assumeIsolated { if self.running { self.t += Float(ev.deltaTime) }; self.now += Float(ev.deltaTime); self.update(Float(ev.deltaTime)) }
        }
        update(0)
        // The real texture arrives in the background; the globe shows plain ocean blue until then.
        if let tex = await EarthAssets.loadTexture(), let m = earthModel {
            var pbr = PhysicallyBasedMaterial()
            pbr.baseColor = .init(texture: .init(tex)); pbr.roughness = 0.95; pbr.metallic = 0.0
            m.model?.materials = [pbr]
        }
    }

    // MARK: Earth

    private func makeEarth() -> Entity {
        let seg = 96, rg = 48
        var pos: [SIMD3<Float>] = [], nor: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], idx: [UInt32] = []
        for j in 0...rg {
            let lat = Float.pi * (0.5 - Float(j) / Float(rg))
            for i in 0...seg {
                let lon = 2 * Float.pi * Float(i) / Float(seg)
                let d = SIMD3<Float>(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))
                pos.append(d * R); nor.append(d); uv.append([Float(i) / Float(seg), Float(j) / Float(rg)])
            }
        }
        for j in 0..<rg { for i in 0..<seg {
            let a = UInt32(j * (seg + 1) + i), b = a + 1, c = a + UInt32(seg + 1), d = c + 1
            idx += [a, c, b, b, c, d]
        } }
        var md = MeshDescriptor(name: "earth")
        md.positions = MeshBuffer(pos); md.normals = MeshBuffer(nor); md.textureCoordinates = MeshBuffer(uv)
        md.primitives = .triangles(idx)
        let mesh = try! MeshResource.generate(from: [md])
        let e = ModelEntity(mesh: mesh, materials: [lit(0x2a7fc4)])
        e.position = C
        e.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        earthModel = e
        if let t = EarthAssets.texture { var pbr = PhysicallyBasedMaterial(); pbr.baseColor = .init(texture: .init(t)); pbr.roughness = 0.95; e.model?.materials = [pbr] }
        var am = UnlitMaterial(color: UIColor(hex: 0x6fb4ff)); am.faceCulling = .front
        let atmo = model(.generateSphere(radius: R * 1.06), am)
        atmo.components.set(OpacityComponent(opacity: 0.22))
        let root = Entity(); root.addChild(e); atmo.position = C; root.addChild(atmo)
        return root
    }

    // MARK: scenery

    private func buildScenery() {
        for (x, z, s) in [(-2.4, -0.7, 1.0), (-1.1, -1.7, 0.8), (2.2, -1.2, 1.1), (0.6, -2.0, 0.9), (-3.4, 0.5, 0.8),
                          (3.6, -0.2, 0.9), (-0.6, -3.0, 0.9), (1.5, -2.8, 0.8), (-2.6, 1.0, 0.8), (2.6, 1.0, 0.7)] as [(Float, Float, Float)] {
            let t = Entity()
            t.addChild(model(.generateCylinder(height: 0.2, radius: 0.045), lit(0x5a3b24), at: [0, 0.1, 0]))
            t.addChild(model(.generateCone(height: 0.5, radius: 0.24), lit(0x1f6b44), at: [0, 0.4, 0]))
            t.addChild(model(.generateCone(height: 0.38, radius: 0.18), lit(0x2b8456), at: [0, 0.68, 0]))
            t.scale = .init(repeating: s * 1.1)
            stand(t, x, z)
        }
        for (x, z) in houses {
            let h = Entity()
            h.addChild(model(.generateBox(width: 0.55, height: 0.34, depth: 0.42), lit(0xe6d9bf), at: [0, 0.17, 0]))
            for s in [-1, 1] as [Float] {
                let r = model(.generateBox(width: 0.34, height: 0.03, depth: 0.5), lit(0xb5533c), at: [s * 0.13, 0.47, 0])
                r.orientation = simd_quatf(angle: -s * 0.75, axis: [0, 0, 1]); h.addChild(r)
            }
            h.addChild(model(.generateBox(width: 0.11, height: 0.11, depth: 0.02), glow(0xffd36a), at: [0.1, 0.18, 0.22]))
            h.scale = .init(repeating: 1.15)
            stand(h, x, z, spin: x * 0.15)
        }
        let p = Entity()
        let skin = lit(0xf0c3a0), shirt = lit(0xff6b4a), pants = lit(0x2d3a63)
        p.addChild(limb([-0.055, 0.30, 0], [-0.06, 0.05, 0], 0.048, pants))
        p.addChild(limb([0.055, 0.30, 0], [0.06, 0.05, 0], 0.048, pants))
        p.addChild(model(.generateSphere(radius: 0.055), lit(0x222222), at: [-0.06, 0.03, 0.03]))
        p.addChild(model(.generateSphere(radius: 0.055), lit(0x222222), at: [0.06, 0.03, 0.03]))
        p.addChild(limb([0, 0.34, 0], [0, 0.55, 0], 0.092, shirt))
        p.addChild(limb([-0.09, 0.55, 0], [-0.14, 0.34, 0], 0.032, shirt))
        p.addChild(model(.generateSphere(radius: 0.034), skin, at: [-0.14, 0.32, 0]))
        p.addChild(limb([0.09, 0.55, 0], [0.2, 0.6, 0], 0.032, shirt))
        p.addChild(limb([0.2, 0.6, 0], [0.29, 0.74, 0], 0.03, shirt))
        p.addChild(model(.generateSphere(radius: 0.036), skin, at: [0.3, 0.76, 0]))
        p.addChild(model(.generateCylinder(height: 0.05, radius: 0.035), skin, at: [0, 0.62, 0]))
        p.addChild(model(.generateSphere(radius: 0.092), skin, at: [0, 0.71, 0]))
        p.addChild(model(.generateSphere(radius: 0.096), lit(0x2a1a14), at: [0, 0.73, -0.016]))
        let phone = model(.generateBox(width: 0.08, height: 0.135, depth: 0.014), glow(0x9fe6ff), at: [0.325, 0.82, 0])
        phone.orientation = simd_quatf(angle: -0.35, axis: [0, 0, 1]); p.addChild(phone)
        let g = Entity(); g.position = [0.34, 0.9, 0.1]
        g.components.set(PointLightComponent(color: UIColor(hex: 0x9fe6ff), intensity: 4000, attenuationRadius: 2.5))
        p.addChild(g); phoneGlow = g
        p.scale = .init(repeating: 1.5)
        stand(p, 0, 0)
    }

    // MARK: satellite

    private func makeSat(beaconHex: UInt32) -> (Entity, ModelEntity) {
        let s = Entity()
        let gold = lit(0xd9a93a, rough: 0.4, metal: true), panel = lit(0x2c5fd6, rough: 0.3, metal: true)
        s.addChild(model(.generateBox(width: 0.5, height: 0.5, depth: 0.6), gold))
        for sg in [-1, 1] as [Float] {
            let arm = model(.generateCylinder(height: 0.4, radius: 0.02), lit(0x999999), at: [sg * 0.45, 0, 0])
            arm.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1]); s.addChild(arm)
            s.addChild(model(.generateBox(width: 0.9, height: 0.02, depth: 0.5), panel, at: [sg * 1.1, 0, 0]))
            for i in -1...1 { s.addChild(model(.generateBox(width: 0.012, height: 0.03, depth: 0.5), lit(0x9db8ff), at: [sg * 1.1 + Float(i) * 0.28, 0, 0])) }
        }
        let dish = model(.generateCone(height: 0.18, radius: 0.22), lit(0xe8e8e8), at: [0, -0.38, 0])
        dish.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0]); s.addChild(dish)
        let b = model(.generateSphere(radius: 0.07), glow(beaconHex), at: [0, -0.5, 0]); s.addChild(b)
        return (s, b)
    }

    private func buildSatellite() {
        let (s, b) = makeSat(beaconHex: 0x7fd8ff)
        sat.addChild(s); beacon = b
        sat.scale = .init(repeating: 0.8)
        let l = Entity(); l.position = [0, -0.9, 0.8]
        l.components.set(PointLightComponent(color: UIColor(hex: 0x7fd8ff), intensity: 6000, attenuationRadius: 5))
        sat.addChild(l); satLight = l
        satSprite = sprite(0x9fe6ff, size: 1.3); satSprite.position = [0, -0.5, 0.1]; sat.addChild(satSprite)
    }

    private func sprite(_ hex: UInt32, size: Float) -> ModelEntity {
        var m = UnlitMaterial()
        if let tex = EarthAssets.glowTex { m.color = .init(tint: UIColor(hex: hex), texture: .init(tex)) } else { m.color = .init(tint: UIColor(hex: hex).withAlphaComponent(0.2)) }
        m.blending = .transparent(opacity: .init(floatLiteral: 1))
        let e = ModelEntity(mesh: .generatePlane(width: size, height: size), materials: [m])
        e.components.set(BillboardComponent()); setOpacity(e, 0.7)
        return e
    }

    // MARK: beams

    private func buildBeams(_ content: RealityViewCameraContent) {
        let cone = MeshResource.generateCone(height: 1, radius: 1)
        // layered translucent cones: bright thin core inside a wider soft halo = luminous beam
        main = BeamRig(mesh: cone, color: 0x8fe0ff, widths: [1.0, 0.62, 0.3], weights: [0.35, 0.5, 0.8], parent: Entity())
        content.add(main.root)
        for _ in houses { let b = BeamRig(mesh: cone, color: 0x7fd8ff, widths: [1.0, 0.55], weights: [0.4, 0.7], parent: Entity()); side.append(b); content.add(b.root) }
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let n = 48
        for i in 0..<n { let a = 2 * Float.pi * Float(i) / Float(n); pos.append([cos(a) * 0.82, sin(a) * 0.82, 0]); pos.append([cos(a), sin(a), 0]) }
        for i in 0..<n { let a = UInt32(i * 2), b = UInt32(((i + 1) % n) * 2); idx += [a, a + 1, b, b, a + 1, b + 1] }
        var md = MeshDescriptor(name: "ring"); md.positions = MeshBuffer(pos); md.primitives = .triangles(idx)
        let ringMesh = try! MeshResource.generate(from: [md])
        for _ in 0..<5 { let r = model(ringMesh, glow(0xbff2ff, culling: false)); setOpacity(r, 0); rings.append(r); content.add(r) }
        groundRing = model(ringMesh, glow(0x9fe6ff, culling: false)); setOpacity(groundRing, 0); content.add(groundRing)
        for _ in 0..<44 {
            let s = model(.generateSphere(radius: 0.028), glow(0xfff0b0)); content.add(s)
            sparks.append((s, .random(in: 0...1), .random(in: 0...6.28), .random(in: 0.2...1)))
        }
        phoneSprite = sprite(0x9fe6ff, size: 1.0); content.add(phoneSprite)
    }

    private func buildStars(_ content: RealityViewCameraContent) {
        for i in 0..<110 {
            let m = model(.generateSphere(radius: Float.random(in: 0.012...0.04)), glow(i % 9 == 0 ? 0xffe3a8 : 0xffffff))
            m.position = [Float.random(in: -14...14), Float.random(in: -1...17), -14]
            content.add(m); stars.append((m, Float.random(in: 0...6.28)))
        }
        for i in 0..<90 {   // below the globe, seen from above in cards 3 and 4
            let m = model(.generateSphere(radius: Float.random(in: 0.015...0.05)), glow(i % 9 == 0 ? 0xffe3a8 : 0xffffff))
            m.position = [Float.random(in: -12...12), -14, Float.random(in: -12...12)]
            starsTop.addChild(m)
        }
        content.add(starsTop); starsTop.isEnabled = mode >= 2
    }

    // MARK: card 2 pieces

    private func buildDelay(_ content: RealityViewCameraContent) {
        pulse.addChild(model(.generateSphere(radius: 0.13), glow(0xfff4c4)))
        pulseGlow = sprite(0xffd24a, size: 1.1); pulse.addChild(pulseGlow)
        content.add(pulse)
        for i in 0..<6 { let m = model(.generateSphere(radius: 0.09 - Float(i) * 0.011), glow(0xffd24a)); content.add(m); trail.append(m) }
        for _ in 0..<3 { let m = model(.generateCylinder(height: 1, radius: 1), glow(0xffffff)); setOpacity(m, 0); content.add(m); dimParts.append(m) }
    }

    // MARK: cards 3 and 4 pieces

    private func buildTriangulation(_ content: RealityViewCameraContent) {
        let defs: [(Float, Float, UInt32)] = [(0.30, 150 * .pi / 180, 0x5aa9ff), (0.27, 30 * .pi / 180, 0x5ee0a0), (0.33, 270 * .pi / 180, 0xff7ad9)]
        let n = mode == 2 ? 2 : 3
        for k in 0..<n {
            var d = Tri(psi: defs[k].0, phi: defs[k].1, col: defs[k].2)
            d.s = [sin(d.psi) * cos(d.phi), cos(d.psi), sin(d.psi) * sin(d.phi)]
            let (s, b) = makeSat(beaconHex: d.col)
            d.sat.addChild(s); d.beacon = b
            d.sat.position = C + d.s * (R + 1.7); d.sat.orientation = simd_quatf(from: [0, 1, 0], to: d.s); d.sat.scale = .zero
            content.add(d.sat)
            let e1 = simd_normalize((P - d.s * cos(d.psi)) / sin(d.psi)), e2 = simd_cross(d.s, e1)
            let mat = glow(d.col)
            for j in 0..<SEG {
                let th = Float(j) / Float(SEG) * 2 * .pi
                let p = C + (d.s * cos(d.psi) + (e1 * cos(th) + e2 * sin(th)) * sin(d.psi)) * (R + 0.07)
                let dot = model(.generateSphere(radius: 0.045), mat, at: p); dot.isEnabled = false; content.add(dot); d.dots.append(dot)
            }
            d.line = model(.generateCylinder(height: 1, radius: 1), glow(d.col)); setOpacity(d.line, 0); content.add(d.line)
            tri.append(d)
        }
        let nAB = simd_normalize(simd_cross(tri[0].s, tri[1].s))
        mirror = P - 2 * simd_dot(P, nAB) * nAB
        let wp = { (v: SIMD3<Float>) in self.C + v * (self.R + 0.1) }
        markYou = model(.generateSphere(radius: 0.1), glow(0xffffff), at: wp(P)); markMirror = model(.generateSphere(radius: 0.1), glow(0xffffff), at: wp(mirror))
        content.add(markYou); content.add(markMirror)
        let pm = SimpleMaterial(color: UIColor(hex: 0xff6b4a), roughness: 0.5, isMetallic: false)
        pin.addChild(model(.generateSphere(radius: 0.17), pm, at: [0, 0.62, 0]))
        let tip = model(.generateCone(height: 0.4, radius: 0.11), pm, at: [0, 0.2, 0]); tip.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0]); pin.addChild(tip)
        content.add(pin)
        pinFlat = groundRing
    }

    // MARK: frame

    private func project(_ p: SIMD3<Float>) -> (Double, Double, Bool) {
        let f = simd_normalize(camTarget - camPos), r = simd_normalize(simd_cross(f, [0, 1, 0])), u = simd_cross(r, f)
        let v = p - camPos, z = simd_dot(v, f)
        guard z > 0.1 else { return (0, 0, false) }
        let th = tan(fov * .pi / 360)
        let nx = simd_dot(v, r) / (z * th * aspect), ny = simd_dot(v, u) / (z * th)
        return (Double(nx * 0.5 + 0.5), Double(0.5 - ny * 0.5), true)
    }
    private func label(_ id: String, _ text: String, at p: SIMD3<Float>, dx: CGFloat = 0, dy: CGFloat = 0, _ o: Float, you: Bool = false) -> SceneLabel {
        let (x, y, ok) = project(p)
        return SceneLabel(id: id, text: text, x: x, y: y, dx: dx, dy: dy, opacity: ok ? Double(max(0, min(1, o))) : 0, you: you)
    }

    private var built = false
    func update(_ dt: Float) {
        guard built else { return }
        let a: SIMD3<Float>
        var lbls: [SceneLabel] = []
        var clk: (String, Double)? = nil
        let drift: Float = reduce ? 0 : 1

        // satellite (modes 0, 1)
        if mode < 2 {
            let th = sin(now * 0.12) * (mode == 0 ? 0.06 : 0.02) * drift - 0.02
            let orbit = R + 6.4
            sat.position = C + [sin(th) * orbit, cos(th) * orbit, -0.6]
            sat.orientation = simd_quatf(angle: -th, axis: [0, 0, 1]) * simd_quatf(angle: sin(now * 0.18) * 0.08 * drift, axis: [0, 1, 0])
            beacon.scale = .init(repeating: 0.8 + 0.4 * sin(now * 6))
            a = sat.position + sat.orientation.act([0, -0.5 * 0.8, 0])
        } else { a = .zero }
        local.isEnabled = true; sat.isEnabled = mode < 2

        // camera
        let pb: Float = mode >= 2 ? smooth(0.2, 2.6, t) : 0
        let camA: SIMD3<Float> = [sin(now * 0.1) * 0.3 * drift, 3.3, 11.5], tgtA: SIMD3<Float> = [0, 3, 0]
        let camB: SIMD3<Float> = [0, 11.5, 5.5], tgtB: SIMD3<Float> = [0, -0.2, 0]
        camPos = camA + (camB - camA) * pb; camTarget = tgtA + (tgtB - tgtA) * pb
        camera.look(at: camTarget, from: camPos, relativeTo: nil)
        local.scale = .init(repeating: mode >= 2 ? max(0.001, 1 - smooth(0.5, 1.6, t)) : 1)
        if mode >= 2 { local.isEnabled = pb < 0.7 }
        for s in stars { s.e.components.set(OpacityComponent(opacity: 0.55 + 0.45 * sin(now * 1.6 + s.ph))) }

        // defaults off
        main.set(0); side.forEach { $0.set(0) }
        rings.forEach { $0.isEnabled = false }; sparks.forEach { $0.e.isEnabled = false }
        phoneSprite.isEnabled = false; satSprite.isEnabled = mode < 2; setOpacity(groundRing, 0)
        satLight.isEnabled = mode < 2
        if mode == 1 { pulse.isEnabled = false; trail.forEach { $0.isEnabled = false } }

        if mode == 0 { runBroadcast(a) }
        if mode == 1 { (lbls, clk) = runDelay(a) }
        if mode >= 2 { lbls = runTriangulation() }

        if labels != lbls { labels = lbls }
        if let c = clk { if clock?.text != c.0 || clock?.opacity != c.1 { clock = (c.0, c.1) } } else if clock != nil { clock = nil }
    }

    private func beamParts(_ a: SIMD3<Float>, _ b: SIMD3<Float>, radius: Float, sparksOn: Bool, ringsOn: Bool, rate: Float = 0.33) {
        let d = b - a, len = simd_length(d), dir = d / len
        let q = simd_quatf(from: [0, 0, 1], to: dir)
        if ringsOn {
            for (i, r) in rings.enumerated() {
                let k = (now * rate + Float(i) / Float(rings.count)).truncatingRemainder(dividingBy: 1)
                r.isEnabled = true; r.position = a + dir * len * k; r.orientation = q
                r.scale = .init(repeating: 0.02 + radius * 0.9 * k); setOpacity(r, sin(k * .pi) * 0.7)
            }
        }
        if sparksOn {
            let u = q.act([1, 0, 0]), v = q.act([0, 1, 0])
            for s in sparks {
                let k = (s.t + now * 0.14).truncatingRemainder(dividingBy: 1), rr = radius * 0.8 * k * s.r
                s.e.isEnabled = true
                s.e.position = a + dir * len * k + u * cos(s.a + now * 1.5) * rr + v * sin(s.a + now * 1.5) * rr
                s.e.scale = .init(repeating: sin(k * .pi) + 0.1)
            }
        }
    }

    private func runBroadcast(_ a: SIMD3<Float>) {
        let ph = t.truncatingRemainder(dividingBy: 7.2), mix = smooth(3.4, 4.2, ph)
        let pulseT = 0.75 + 0.25 * sin(now * 0.33 * 2 * .pi)
        main.aim(from: a, to: phoneW, radius: 0.2); main.set((0.16 + 0.22 * mix) * pulseT * 1.4)
        for (i, sb) in side.enumerated() {
            let g = dirAt(houses[i].0, houses[i].1)
            sb.aim(from: a, to: C + g * R + [0, 0.3, 0], radius: 0.4); sb.set(0.12 * (1 - mix))
        }
        beamParts(a, phoneW, radius: 0.2, sparksOn: true, ringsOn: true)
        phoneSprite.isEnabled = true; phoneSprite.position = phoneW
        let gp = 0.5 + 0.5 * sin(now * 0.33 * 2 * .pi); phoneSprite.scale = .init(repeating: 0.9 + 0.5 * gp + 0.5 * mix)
        let gk = (now * 0.33).truncatingRemainder(dividingBy: 1)
        groundRing.position = [0, 0.03, 0]; groundRing.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        groundRing.scale = .init(repeating: 0.2 + gk * 1.4); setOpacity(groundRing, (1 - gk) * 0.5)
        phoneGlow.components.set(PointLightComponent(color: UIColor(hex: 0x9fe6ff), intensity: 2500 + 5000 * (max(0, sin(now * 0.33 * 2 * .pi)) + mix * 0.6), attenuationRadius: 2.5))
        satSprite.scale = .init(repeating: 0.9 + 0.2 * sin(now * 6))
    }

    private func runDelay(_ a: SIMD3<Float>) -> ([SceneLabel], (String, Double)?) {
        let T: Float = 9.6, ph = t.truncatingRemainder(dividingBy: T), f = 1 - ramp(ph, 9, 9.5)
        let d = phoneW - a, len = simd_length(d), dir = d / len
        main.aim(from: a, to: phoneW, radius: 0.16); main.set(0.22 * f)
        let k = ramp(ph, 1.6, 3.6), fly = k > 0 && k < 1
        pulse.isEnabled = ph < 9; pulse.position = a + dir * len * k
        pulse.scale = .init(repeating: k >= 1 ? 1 + 0.25 * sin(now * 8) : 1)
        for (i, m) in trail.enumerated() { m.isEnabled = fly; m.position = a + dir * len * max(0, k - Float(i + 1) * 0.035) }
        phoneSprite.isEnabled = k >= 1 && f > 0; phoneSprite.position = phoneW; phoneSprite.scale = .init(repeating: 0.9 + 0.3 * sin(now * 8))
        let ek = k >= 1 ? ((ph - 3.6).truncatingRemainder(dividingBy: 1.4)) / 1.4 : 0
        groundRing.position = [0, 0.03, 0]; groundRing.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        groundRing.scale = .init(repeating: 0.2 + ek * 1.4); setOpacity(groundRing, k >= 1 ? (1 - ek) * 0.5 * f : 0)
        phoneGlow.components.set(PointLightComponent(color: UIColor(hex: 0x9fe6ff), intensity: k >= 1 ? 6000 + 2000 * sin(now * 8) : 1500, attenuationRadius: 2.5))
        // dimension line left of the beam
        let dk = smooth(5.0, 5.8, ph), off: SIMD3<Float> = [-1.7, 0, 0]
        let A = a + off, B = phoneW + off
        let lineD = B - A
        dimParts[0].position = (A + B) / 2; dimParts[0].orientation = simd_quatf(from: [0, 1, 0], to: lineD / simd_length(lineD)); dimParts[0].scale = [0.012, simd_length(lineD), 0.012]
        for (i, p) in [A, B].enumerated() { let m = dimParts[i + 1]; m.position = p; m.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1]); m.scale = [0.012, 0.4, 0.012] }
        dimParts.forEach { setOpacity($0, 0.85 * dk * f) }
        var l: [SceneLabel] = []
        l.append(label("sent", "Sent 0.00 s", at: a, dx: 0, dy: -38, (ph < 3.6 ? 1 : 0) * f))
        l.append(label("arr", "Arrives 0.07 s", at: phoneW, dx: 82, dy: -4, (ph > 3.7 ? 1 : 0) * f))
        l.append(label("dist", "About 20,000 km", at: (A + B) / 2, dx: -6, dy: 0, dk * f))
        return (l, (String(format: "%.2f s", 0.07 * k), Double(f)))
    }

    private func runTriangulation() -> [SceneLabel] {
        let ins: [Float] = mode == 2 ? [0.6, 2.8] : [0.5, 2.1, 3.7]
        let sweepDur: Float = 1.7, total: Float = mode == 2 ? 9.5 : 11.5
        let ph = t.truncatingRemainder(dividingBy: total), f = 1 - ramp(ph, total - 0.8, total - 0.1)
        for i in 0..<tri.count {
            let sIn = smooth(ins[i], ins[i] + 0.6, ph) * f
            tri[i].sat.scale = .init(repeating: 0.6 * sIn); tri[i].sat.isEnabled = sIn > 0.001
            tri[i].beacon.scale = .init(repeating: 0.8 + 0.4 * sin(now * 6 + Float(i)))
            let sw = ramp(ph, ins[i] + 0.6, ins[i] + 0.6 + sweepDur)
            let cnt = Int(smooth(0, 1, sw) * Float(SEG))
            if mode >= 2 && (cnt != shown[i] || f < 1 || ph < 0.1) {
                let c = f < 1 ? Int(Float(cnt) * f) : cnt
                if c != shown[i] { for j in 0..<SEG { tri[i].dots[j].isEnabled = j < c }; shown[i] = c }
            }
            let tip = tri[i].sat.position + tri[i].sat.orientation.act([0, -0.5 * 0.6, 0])
            let to: SIMD3<Float> = [0, 0.3, 0], dd = to - tip, L = simd_length(dd)
            tri[i].line.position = tip + dd / 2; tri[i].line.orientation = simd_quatf(from: [0, 1, 0], to: dd / L); tri[i].line.scale = [0.01, L, 0.01]
            setOpacity(tri[i].line, sw >= 1 ? 0.5 * f : 0)
        }
        let nT = tri.count, lastDone = ins[nT - 1] + 0.6 + sweepDur
        let pk = 0.8 + 0.35 * sin(now * 7)
        let pinAt = lastDone + 0.4
        let two = ins[1] + 0.6 + sweepDur
        markYou.isEnabled = ph > two && mode == 2 || (mode == 3 && ph > two)
        markMirror.isEnabled = ph > two && (mode == 2 || ph < lastDone + 1.0)
        markYou.scale = .init(repeating: pk * f)
        markMirror.scale = .init(repeating: pk * (mode == 3 ? 1 - ramp(ph, lastDone, lastDone + 1.0) : 1) * f)
        var l: [SceneLabel] = []
        if mode == 3 {
            let pinK = smooth(pinAt, pinAt + 0.6, ph) * f
            pin.isEnabled = pinK > 0.001; pin.scale = .init(repeating: pinK)
            pin.position = [0, 0.1 + (1 - pinK) * 1.4 + sin(now * 3) * 0.03, 0]
            if pinK > 0.9 { markYou.isEnabled = false }
            let gk = max(0, (ph - pinAt - 0.4).truncatingRemainder(dividingBy: 1.4)) / 1.4
            groundRing.position = [0, 0.04, 0]; groundRing.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            groundRing.scale = .init(repeating: 0.25 + gk * 1.1); setOpacity(groundRing, pinK > 0.9 ? (1 - gk) * 0.55 * f : 0)
            l.append(label("you", "You", at: [0, 1.45, 0], dy: -4, ramp(ph, pinAt + 0.3, pinAt + 0.7) * f, you: true))
        } else { pin.isEnabled = false }
        return l
    }
}
