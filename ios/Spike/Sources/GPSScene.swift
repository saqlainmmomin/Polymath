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
private func mix(_ a: Float, _ b: Float, _ k: Float) -> Float { a + (b - a) * k }
private func mix3(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ k: Float) -> SIMD3<Float> { a + (b - a) * k }

/// A rounded limb: cylinder between two points with sphere end caps (a capsule).
private func limb(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ r: Float, _ mat: SimpleMaterial) -> Entity {
    let e = Entity(), d = b - a, len = simd_length(d)
    let cyl = model(.generateCylinder(height: len, radius: r), mat, at: (a + b) / 2)
    cyl.orientation = simd_quatf(from: [0, 1, 0], to: d / len)
    e.addChild(cyl); e.addChild(model(.generateSphere(radius: r), mat, at: a)); e.addChild(model(.generateSphere(radius: r), mat, at: b))
    return e
}

/// Triangular prism (ridge along z) with flat shading: a gabled roof.
private func prismMesh(_ w: Float, _ h: Float, _ d: Float) -> MeshResource {
    let hw = w / 2, hd = d / 2
    let a: SIMD3<Float> = [-hw, 0, hd], b: SIMD3<Float> = [hw, 0, hd], c: SIMD3<Float> = [0, h, hd]
    let a2: SIMD3<Float> = [-hw, 0, -hd], b2: SIMD3<Float> = [hw, 0, -hd], c2: SIMD3<Float> = [0, h, -hd]
    var pos: [SIMD3<Float>] = [], nor: [SIMD3<Float>] = [], idx: [UInt32] = []
    func face(_ pts: [SIMD3<Float>], _ n: SIMD3<Float>, _ tris: [UInt32]) {
        let o = UInt32(pos.count); pos += pts; nor += Array(repeating: simd_normalize(n), count: pts.count); idx += tris.map { $0 + o }
    }
    face([a, b, c], [0, 0, 1], [0, 1, 2])
    face([b2, a2, c2], [0, 0, -1], [0, 1, 2])
    face([a2, a, c, c2], [-h, hw, 0], [0, 1, 2, 0, 2, 3])
    face([b, b2, c2, c], [h, hw, 0], [0, 1, 2, 0, 2, 3])
    face([a2, b2, b, a], [0, -1, 0], [0, 1, 2, 0, 2, 3])
    var md = MeshDescriptor(name: "prism"); md.positions = MeshBuffer(pos); md.normals = MeshBuffer(nor); md.primitives = .triangles(idx)
    return try! MeshResource.generate(from: [md])
}

// MARK: - glow kit: soft textures, shared meshes and materials (built once, reused by every card)

enum GlowTex { case radial, ribbon }

@MainActor
enum GlowKit {
    static var radial: TextureResource?, ribbon: TextureResource?
    static var cache: [UInt64: UnlitMaterial] = [:]
    static var quad: MeshResource!, annulus: MeshResource!, flat: MeshResource!, earthMesh: MeshResource!
    static var chunks: [String: MeshResource] = [:]
    static let R: Float = 5
    /// Camera-facing sprites are turned by hand each frame: BillboardComponent crashed the engine when a card was swapped in mid-swipe.
    static var current: [Entity] = []

    static func prepare() {
        guard quad == nil else { return }
        // Falloff textures: smooth, no visible rim, so glows never read as flat discs.
        radial = texture(96, 96) { u, v in
            let r = hypot(2 * u - 1, 2 * v - 1)
            return min(1, pow(max(0, 1 - r), 2.4) + 0.4 * pow(max(0, 1 - r * 4), 2))
        }
        ribbon = texture(64, 4) { u, _ in pow(max(0, 1 - abs(2 * u - 1)), 1.7) }
        quad = mesh([[-0.5, -0.5, 0], [0.5, -0.5, 0], [0.5, 0.5, 0], [-0.5, 0.5, 0]], [[0, 0], [1, 0], [1, 1], [0, 1]], [0, 1, 2, 0, 2, 3])
        var p: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], idx: [UInt32] = []
        let n = 72
        for i in 0..<n {
            let a = 2 * Float.pi * Float(i) / Float(n)
            p.append([cos(a) * 0.95, sin(a) * 0.95, 0]); uv.append([0, 0]); p.append([cos(a), sin(a), 0]); uv.append([1, 0])
        }
        for i in 0..<n { let a = UInt32(i * 2), b = UInt32(((i + 1) % n) * 2); idx += [a, a + 1, b, b, a + 1, b + 1] }
        annulus = mesh(p, uv, idx)
        flat = .generatePlane(width: 1, depth: 1)
        earthMesh = makeEarthMesh()
    }

    private static func texture(_ w: Int, _ h: Int, _ f: (Float, Float) -> Float) -> TextureResource? {
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), let data = ctx.data else { return nil }
        let px = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        for y in 0..<h { for x in 0..<w {
            let a = f((Float(x) + 0.5) / Float(w), (Float(y) + 0.5) / Float(h))
            let v = UInt8(max(0, min(1, a)) * 255), o = (y * w + x) * 4
            px[o] = v; px[o + 1] = v; px[o + 2] = v; px[o + 3] = v
        } }
        guard let img = ctx.makeImage() else { return nil }
        return try? TextureResource(image: img, options: .init(semantic: .color))
    }

    private static func mesh(_ p: [SIMD3<Float>], _ uv: [SIMD2<Float>], _ idx: [UInt32], normals: [SIMD3<Float>]? = nil) -> MeshResource {
        var md = MeshDescriptor(name: "m")
        md.positions = MeshBuffer(p); md.textureCoordinates = MeshBuffer(uv)
        md.normals = MeshBuffer(normals ?? Array(repeating: [0, 0, 1], count: p.count))
        md.primitives = .triangles(idx)
        return try! MeshResource.generate(from: [md])
    }

    /// One short arc of a ring on the globe (polar angle psi around +y), `width` world units across, soft edges via uv.
    static func chunk(psi: Float, width: Float, dTheta: Float) -> MeshResource {
        let key = "\(psi)-\(width)-\(dTheta)"
        if let m = chunks[key] { return m }
        let rad = R + 0.06, hw = width / (2 * rad)
        var p: [SIMD3<Float>] = [], nr: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], idx: [UInt32] = []
        let steps = 2
        for i in 0...steps {
            let th = dTheta * 1.18 * Float(i) / Float(steps)
            for (j, pol) in [psi - hw, psi + hw].enumerated() {
                let d = SIMD3<Float>(sin(pol) * cos(th), cos(pol), -sin(pol) * sin(th))
                p.append(d * rad); nr.append(d); uv.append([Float(j), Float(i) / Float(steps)])
            }
        }
        for i in 0..<steps { let a = UInt32(i * 2); idx += [a, a + 1, a + 2, a + 2, a + 1, a + 3] }
        let m = mesh(p, uv, idx, normals: nr); chunks[key] = m; return m
    }

    static func material(_ tex: GlowTex, _ hex: UInt32, _ level: Int) -> UnlitMaterial {
        let key = UInt64(hex) << 16 | UInt64(level) << 1 | (tex == .radial ? 0 : 1)
        if let m = cache[key] { return m }
        var m = UnlitMaterial()
        if let t = tex == .radial ? radial : ribbon { m.color = .init(tint: UIColor(hex: hex), texture: .init(t)) }
        else { m.color = .init(tint: UIColor(hex: hex).withAlphaComponent(0.2)) }
        m.blending = .transparent(opacity: .init(floatLiteral: Float(level) / 12))
        m.faceCulling = .none
        cache[key] = m; return m
    }

    private static func makeEarthMesh() -> MeshResource {
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
        return mesh(pos, uv, idx, normals: nor)
    }
}

/// A glow piece (or a set sharing one look). Fades by swapping to pre-built materials: opacity components set per frame were unreliable.
@MainActor
final class Fx {
    let ents: [ModelEntity]; let tex: GlowTex; let hex: UInt32
    private var level = 12
    var e: ModelEntity { ents[0] }
    init(_ tex: GlowTex, _ hex: UInt32, mesh: MeshResource? = nil, count: Int = 1, billboard: Bool = false, parent: Entity? = nil) {
        self.tex = tex; self.hex = hex
        let m = mesh ?? GlowKit.quad!
        ents = (0..<count).map { _ in
            let e = ModelEntity(mesh: m, materials: [GlowKit.material(tex, hex, 12)])
            if billboard { GlowKit.current.append(e) }
            e.isEnabled = false
            parent?.addChild(e)
            return e
        }
    }
    func setLevel(_ o: Float) {
        let l = Int((max(0, min(1, o)) * 12).rounded())
        guard l != level, l > 0 else { return }
        level = l
        let mats = [GlowKit.material(tex, hex, l)]
        for e in ents { e.model?.materials = mats }
    }
    func show(_ o: Float) {
        if o < 0.04 { e.isEnabled = false; return }
        setLevel(o); e.isEnabled = true
    }
    func hide() { for e in ents { e.isEnabled = false } }
}

/// Orient a unit quad so it runs a->b, is `width` wide, and turns its face toward the camera around the beam axis.
private func placeAlong(_ e: Entity, from a: SIMD3<Float>, to b: SIMD3<Float>, width: Float, cam: SIMD3<Float>) {
    let d = b - a, len = simd_length(d)
    guard len > 1e-4 else { return }
    let y = d / len, mid = (a + b) / 2
    var n = cam - mid; n -= y * simd_dot(n, y)
    n = simd_length(n) < 1e-4 ? [0, 0, 1] : simd_normalize(n)
    let x = simd_cross(y, n)
    e.position = mid; e.orientation = simd_quatf(simd_float3x3(columns: (x, y, n))); e.scale = [width, len, 1]
}

/// Signal beam: hair-thin bright core, soft layered glow, gentle shimmer. Looks additive; no hard edges.
@MainActor
final class Beam {
    let core: Fx, halo: Fx, wide: Fx
    init(hex: UInt32, parent: Entity) {
        core = Fx(.ribbon, 0xffffff, parent: parent); halo = Fx(.ribbon, hex, parent: parent); wide = Fx(.ribbon, hex, parent: parent)
    }
    func aim(_ a: SIMD3<Float>, _ b: SIMD3<Float>, cam: SIMD3<Float>, o: Float, now: Float, phase: Float = 0, thick: Float = 1) {
        guard o > 0.02 else { core.hide(); halo.hide(); wide.hide(); return }
        let sh = 0.85 + 0.15 * sin(now * 6 + phase)
        placeAlong(core.e, from: a, to: b, width: 0.035 * thick, cam: cam); core.show(0.9 * o)
        placeAlong(halo.e, from: a, to: b, width: 0.16 * thick * (0.92 + 0.08 * sh), cam: cam); halo.show(0.5 * o * sh)
        placeAlong(wide.e, from: a, to: b, width: 0.5 * thick, cam: cam); wide.show(0.2 * o)
    }
    func hide() { core.hide(); halo.hide(); wide.hide() }
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

struct ClockInfo: Equatable { var title: String; var text: String; var opacity: Double }

// MARK: - scene

/// One RealityKit scene per card. mode: 0 listening, 1 storm, 2 thunderclap, 3 one ring (camera swings top-down), 4 rings meet.
@MainActor
final class GPSScene: ObservableObject {
    let mode: Int
    @Published var labels: [SceneLabel] = []
    @Published var clock: ClockInfo?
    var aspect: Float = 0.7

    private let R: Float = 5
    private var C: SIMD3<Float> { [0, -R, 0] }
    private var t: Float = 0, now: Float = 0
    private var running = false, reduce = false
    private var sub: EventSubscription?
    /// Moment shown as a still frame under Reduce Motion (everything of the story visible).
    private let restTime: [Float] = [2.2, 1.45, 6.2, 9.0, 10.6]

    private let camera = PerspectiveCamera()
    private var camPos: SIMD3<Float> = [0, 3.8, 12.5], camTarget: SIMD3<Float> = [0, 3.6, 0]
    private let fov: Float = 48

    private let world = Entity(), local = Entity()
    private let sunL = DirectionalLight()
    private var stars: [(e: ModelEntity, ph: Float)] = []
    private var starsTop = Entity()
    private var earthModel: ModelEntity?
    private var personPos: SIMD3<Float> = .zero, up: SIMD3<Float> = [0, 1, 0]
    private var phoneW: SIMD3<Float> = [0.49, 1.23, 0]
    private var phoneGlow = Entity()
    private var phoneFlare: Fx!, listenRing: Fx!, ripple: Fx!
    private var built = false
    private var facing: [Entity] = []

    // satellites in the side-view cards
    private var sats: [(root: Entity, beacon: ModelEntity, flare: Fx)] = []
    private var satBase: [SIMD3<Float>] = []
    private let satScale: Float = 0.42

    // mode 0
    private var beams: [Beam] = [], shout: [Fx] = [], comet: [(outer: Fx, inner: Fx)] = []
    // mode 1
    private var cloudParts: [ModelEntity] = [], cloudDark = lit(0x343a55), cloudBright = glow(0xc9c5f5), cloudIsBright = false
    private var bolt: [(a: SIMD3<Float>, b: SIMD3<Float>, core: Fx, halo: Fx)] = []
    private var skyGlow: Fx!
    private var waveRings: Fx!
    private var rain: [(f: Fx, x: Float, sp: Float, ph: Float)] = []
    private var bracket: [Fx] = []
    private var boltBase: SIMD3<Float> = .zero
    // mode 2
    private var pulseCore = ModelEntity(), pulseFlare: Fx!, trail: [Fx] = [], dimLine: [Fx] = []
    // modes 3, 4
    private let SEGS = 48
    private final class RingRig {
        let psi: Float, hex: UInt32, s: SIMD3<Float>, q0: simd_quatf
        let sat = Entity(); var beacon: ModelEntity!, flare: Fx!, core: Fx!, halo: Fx!, head: Fx!
        var shown = 0
        init(psi: Float, hex: UInt32, s: SIMD3<Float>) { self.psi = psi; self.hex = hex; self.s = s; q0 = simd_quatf(from: [0, 1, 0], to: s) }
        func point(_ th: Float, _ rad: Float, c: SIMD3<Float>) -> SIMD3<Float> {
            let e1 = q0.act([1, 0, 0]), e2 = q0.act([0, 0, -1])
            return c + (s * cos(psi) + (e1 * cos(th) + e2 * sin(th)) * sin(psi)) * rad
        }
    }
    private var rigs: [RingRig] = []
    private var markYou: ModelEntity!, markMirror: ModelEntity!, markYouG: Fx!, markMirrorG: Fx!
    private var pin = Entity(), mirror: SIMD3<Float> = [0, 1, 0]
    private var dot = ModelEntity(), dotGlow: Fx!, dotTrail: [Fx] = []
    private var labelTheta: Float = 0

    init(mode: Int) { self.mode = mode }

    func setActive(_ active: Bool, reduce r: Bool) {
        reduce = r
        if r { running = false; t = restTime[mode]; update(0); return }
        if active && !running { t = 0 }
        running = active
        if !active { update(0) }
    }

    private func dirAt(_ dx: Float, _ dz: Float) -> SIMD3<Float> { simd_normalize([dx / R, 1, dz / R]) }
    private func groundPoint(_ dx: Float, _ dz: Float = 0) -> SIMD3<Float> { C + dirAt(dx, dz) * R }
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
        GlowKit.prepare()
        GlowKit.current = []

        sunL.light.intensity = mode == 1 ? 1300 : 2600; sunL.light.color = mode == 1 ? UIColor(hex: 0xb6c4ff) : UIColor(hex: 0xfff0d6)
        sunL.look(at: .zero, from: [-4, 6, 8], relativeTo: nil)
        content.add(sunL)
        let fill = DirectionalLight()
        fill.light.intensity = 450; fill.light.color = UIColor(hex: 0x6f8cff)
        fill.look(at: .zero, from: [5, 2, 4], relativeTo: nil)
        content.add(fill)

        content.add(world)
        content.add(makeEarth())
        if mode <= 3 {
            world.addChild(local)
            switch mode {
            case 1: buildScenery(personDX: 0, houses: [(-1.2, -1.0, 1), (1.9, -0.4, 4), (3.3, -1.5, 3), (-3.3, -1.7, 2), (0.9, -2.0, 0)])
            default: buildScenery(personDX: 0, houses: [(-1.9, -0.5, 0), (1.9, -0.4, 1), (3.3, -1.5, 3), (-3.3, -1.7, 2), (-0.9, -2.0, 4)])
            }
            buildReceive()
        }
        switch mode {
        case 0: buildListen()
        case 1: buildStorm()
        case 2: buildThunder()
        case 3: buildRing()
        default: buildCross()
        }
        buildStars()
        facing = GlowKit.current; GlowKit.current = []
        built = true
        sub = content.subscribe(to: SceneEvents.Update.self) { [weak self] ev in
            guard let self else { return }
            MainActor.assumeIsolated {
                if self.running { self.t += Float(ev.deltaTime) }
                if !self.reduce { self.now += Float(ev.deltaTime) }
                self.update(Float(ev.deltaTime))
            }
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
        let e = ModelEntity(mesh: GlowKit.earthMesh, materials: [lit(0x2a7fc4)])
        e.position = C
        e.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        earthModel = e
        if let t = EarthAssets.texture { var pbr = PhysicallyBasedMaterial(); pbr.baseColor = .init(texture: .init(t)); pbr.roughness = 0.95; e.model?.materials = [pbr] }
        var am = UnlitMaterial(color: UIColor(hex: mode == 1 ? 0x4a5f9a : 0x6fb4ff)); am.faceCulling = .front
        let atmo = model(.generateSphere(radius: R * 1.06), am)
        atmo.components.set(OpacityComponent(opacity: 0.2))
        let root = Entity(); root.addChild(e); atmo.position = C; root.addChild(atmo)
        return root
    }

    // MARK: scenery

    private func makeHouse(_ v: Int) -> Entity {
        let wallC: [UInt32] = [0xe6d9bf, 0xd8b4a0, 0xb9cde0, 0xe9d38f, 0xcfd9c0]
        let roofC: [UInt32] = [0xb5533c, 0x56688a, 0x7a4a3a, 0x9a3f4d, 0x4f6f5a]
        let dims: [(Float, Float, Float)] = [(0.55, 0.34, 0.42), (0.74, 0.4, 0.5), (0.46, 0.5, 0.4), (0.62, 0.3, 0.46), (0.5, 0.38, 0.44)]
        let (w, h, d) = dims[v % 5], rh = 0.18 + w * 0.17
        let e = Entity()
        e.addChild(model(.generateBox(width: w, height: h, depth: d), lit(wallC[v % 5]), at: [0, h / 2, 0]))
        e.addChild(model(prismMesh(w + 0.18, rh, d + 0.16), lit(roofC[v % 5], rough: 0.8), at: [0, h - 0.015, 0]))
        e.addChild(model(.generateBox(width: 0.07, height: rh * 0.9, depth: 0.07), lit(0x6b4a40), at: [w * (v % 2 == 0 ? 0.24 : -0.24), h + rh * 0.4, -d * 0.12]))
        let door = model(.generateBox(width: 0.1, height: 0.2, depth: 0.016), lit(0x5a3524), at: [-w * 0.24, 0.1, d / 2 + 0.006])
        e.addChild(door)
        e.addChild(model(.generateSphere(radius: 0.008), lit(0xe8c36a, rough: 0.4, metal: true), at: [-w * 0.24 + 0.032, 0.1, d / 2 + 0.018]))
        let wx = w * 0.22, wy = h * 0.58
        e.addChild(model(.generateBox(width: 0.14, height: 0.14, depth: 0.012), lit(0x3a2a24), at: [wx, wy, d / 2 + 0.003]))
        e.addChild(model(.generateBox(width: 0.105, height: 0.105, depth: 0.012), glow(0xffc864), at: [wx, wy, d / 2 + 0.01]))
        e.addChild(model(.generateBox(width: 0.012, height: 0.105, depth: 0.014), lit(0x3a2a24), at: [wx, wy, d / 2 + 0.012]))
        e.addChild(model(.generateBox(width: 0.1, height: 0.1, depth: 0.012), glow(0xffb84d), at: [w / 2 + 0.004, wy, 0.0]).also { $0.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) })
        let halo = Fx(.radial, 0xffb347, billboard: true, parent: e); halo.e.position = [wx, wy, d / 2 + 0.05]; halo.e.scale = .init(repeating: 0.6); halo.show(0.45)
        let spill = Fx(.radial, 0xffa63d, mesh: GlowKit.flat, parent: e); spill.e.position = [wx, 0.02, d / 2 + 0.4]; spill.e.scale = [1.5, 1, 1.1]; spill.show(0.5)
        e.scale = .init(repeating: [1.1, 1.3, 1.0, 1.2, 1.15][v % 5])
        return e
    }

    private func buildScenery(personDX: Float, houses: [(Float, Float, Int)]) {
        for (x, z, s) in [(-2.4, -0.7, 1.0), (-1.1, -1.7, 0.8), (2.2, -1.2, 1.1), (0.6, -2.0, 0.9), (-3.4, 0.5, 0.8),
                          (3.6, -0.2, 0.9), (-0.6, -3.0, 0.9), (1.5, -2.8, 0.8), (-2.6, 1.0, 0.8), (2.6, 1.0, 0.7)] as [(Float, Float, Float)] {
            if abs(x - personDX) < 0.5 && abs(z) < 0.8 { continue }
            let t = Entity()
            t.addChild(model(.generateCylinder(height: 0.2, radius: 0.045), lit(0x5a3b24), at: [0, 0.1, 0]))
            t.addChild(model(.generateCone(height: 0.5, radius: 0.24), lit(0x1f6b44), at: [0, 0.4, 0]))
            t.addChild(model(.generateCone(height: 0.38, radius: 0.18), lit(0x2b8456), at: [0, 0.68, 0]))
            t.scale = .init(repeating: s * 1.1)
            stand(t, x, z)
        }
        for (x, z, v) in houses { stand(makeHouse(v), x, z, spin: x * 0.12) }
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
        g.components.set(PointLightComponent(color: UIColor(hex: 0x9fe6ff), intensity: 3000, attenuationRadius: 2.5))
        p.addChild(g); phoneGlow = g
        p.scale = .init(repeating: 1.5)
        stand(p, personDX, 0)
        personPos = p.position; up = simd_normalize(personPos - C)
        phoneW = personPos + p.orientation.act([0.49, 1.23, 0.05])
    }

    /// Glow pieces on the person: end flare for arriving signals, converging "listening" ring, ground ripple.
    private func buildReceive() {
        phoneFlare = Fx(.radial, 0x9fe6ff, billboard: true, parent: world)
        listenRing = Fx(.ribbon, 0xbff2ff, mesh: GlowKit.annulus, billboard: true, parent: world)
        ripple = Fx(.ribbon, 0x9fe6ff, mesh: GlowKit.annulus, parent: world)
    }
    private func flareAt(_ k: Float, base: Float = 0.3) {   // k 0...1 intensity of the arrival flare
        phoneFlare.e.position = phoneW
        phoneFlare.e.scale = .init(repeating: 0.7 + 1.0 * k)
        phoneFlare.show(base + (1 - base) * k)
        phoneGlow.components.set(PointLightComponent(color: UIColor(hex: 0x9fe6ff), intensity: 1800 + 6000 * k, attenuationRadius: 2.5))
    }
    private func ground(_ k: Float, _ o: Float) {   // flat ripple spreading on the ground around the person
        guard o > 0.03 else { ripple.hide(); return }
        ripple.e.position = personPos + up * 0.04
        ripple.e.orientation = simd_quatf(from: [0, 0, 1], to: up)
        ripple.e.scale = .init(repeating: 0.2 + k * 1.3); ripple.show(o)
    }
    private func listen(_ p: Float) {   // ring contracting onto the phone: "ear"
        guard p > 0.001 && p < 0.999 else { listenRing.hide(); return }
        listenRing.e.position = phoneW; listenRing.e.scale = .init(repeating: 0.85 * (1 - p) + 0.12)
        listenRing.show(0.9 * sin(p * .pi))
    }

    // MARK: satellites

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
    private func addSat(at p: SIMD3<Float>, scale: Float, beacon: UInt32 = 0x7fd8ff) {
        let root = Entity(), (s, b) = makeSat(beaconHex: beacon)
        root.addChild(s); root.scale = .init(repeating: scale); root.position = p
        let fl = Fx(.radial, 0x9fe6ff, billboard: true, parent: root); fl.e.position = [0, -0.5, 0.1]; fl.show(0.7)
        world.addChild(root); sats.append((root, b, fl)); satBase.append(p)
    }
    private func satTip(_ i: Int) -> SIMD3<Float> { sats[i].root.position + sats[i].root.orientation.act([0, -0.5 * satScale * (mode == 2 ? 1.9 : 1), 0]) }

    // MARK: per-mode pieces

    private func buildListen() {
        for p in [SIMD3<Float>(-2.5, 6.9, -0.8), [0.1, 7.9, -1.2], [2.7, 6.6, -0.6]] { addSat(at: p, scale: satScale) }
        for i in 0..<3 {
            beams.append(Beam(hex: 0x8fe0ff, parent: world))
            shout.append(Fx(.ribbon, 0xffd96b, mesh: GlowKit.annulus, count: 2, billboard: true, parent: world))
            comet.append((Fx(.radial, 0x9fe6ff, parent: world), Fx(.radial, 0xffffff, parent: world)))
            _ = i
        }
    }

    private func buildStorm() {
        let cloud = Entity(); cloud.position = [-2.7, 5.0, -0.8]
        for (x, y, z, r) in [(0, 0, 0, 1.1), (-0.95, -0.2, 0.2, 0.8), (0.95, -0.15, 0, 0.85), (-0.3, 0.45, 0, 0.8), (0.5, 0.4, 0.1, 0.7), (-1.55, -0.35, 0, 0.55), (1.55, -0.3, 0, 0.55)] as [(Float, Float, Float, Float)] {
            let m = model(.generateSphere(radius: r), cloudDark, at: [x, y, z]); m.scale = [1.15, 0.7, 0.9]
            cloud.addChild(m); cloudParts.append(m)
        }
        world.addChild(cloud)
        boltBase = groundPoint(-3.0)
        let bx = boltBase.x, zb: Float = 0.5
        let ys: [Float] = [4.5, 3.5, 2.6, 1.6, 0.7, -0.2], xo: [Float] = [0.3, -0.3, 0.3, -0.25, 0.3, -0.2]
        var pts: [SIMD3<Float>] = (0..<6).map { [bx + xo[$0], ys[$0], zb] }
        pts.append([bx, boltBase.y + 0.03, zb])
        var segs: [(SIMD3<Float>, SIMD3<Float>)] = []
        for i in 0..<(pts.count - 1) { segs.append((pts[i], pts[i + 1])) }
        let b1: SIMD3<Float> = [bx + 0.9, 2.5, zb], b2: SIMD3<Float> = [bx + 0.8, 1.7, zb], c1: SIMD3<Float> = [bx - 0.7, 1.7, zb], c2: SIMD3<Float> = [bx - 0.85, 1.0, zb]
        segs.append((pts[2], b1)); segs.append((b1, b2)); segs.append((pts[3], c1)); segs.append((c1, c2))
        for (a, b) in segs { bolt.append((a, b, Fx(.ribbon, 0xffffff, parent: world), Fx(.ribbon, 0xaab4ff, parent: world))) }
        skyGlow = Fx(.radial, 0x9aa4ff, billboard: true, parent: world); skyGlow.e.position = [-2.7, 3.6, -2]; skyGlow.e.scale = .init(repeating: 11)
        waveRings = Fx(.ribbon, 0x8fd0ff, mesh: GlowKit.annulus, count: 3, billboard: true, parent: world)
        for i in 0..<64 {
            let f = Fx(.ribbon, 0xb7c9ff, parent: world)
            rain.append((f, Float.random(in: (-4.3)...(-1.2)), Float.random(in: 0.8...1.4), Float(i) / 64)); f.show(0.4)
        }
        for _ in 0..<3 { bracket.append(Fx(.ribbon, 0xffffff, parent: world)) }
        ripple.hide()
    }

    private func buildThunder() {
        addSat(at: [0, 6.3, -0.3], scale: satScale * 1.9)
        beams.append(Beam(hex: 0x8fe0ff, parent: world))
        pulseCore = model(.generateSphere(radius: 0.1), glow(0xfff6d0)); world.addChild(pulseCore)
        pulseFlare = Fx(.radial, 0xffd24a, billboard: true, parent: pulseCore); pulseFlare.e.scale = .init(repeating: 1.5)
        for _ in 0..<5 { trail.append(Fx(.radial, 0xffd24a, parent: world)) }
        for _ in 0..<3 { dimLine.append(Fx(.ribbon, 0xffffff, parent: world)) }
    }

    private func newRing(psi: Float, s: SIMD3<Float>, hex: UInt32, height: Float, scale: Float) -> RingRig {
        let r = RingRig(psi: psi, hex: hex, s: s)
        let (body, b) = makeSat(beaconHex: hex)
        r.sat.addChild(body); r.beacon = b
        r.sat.position = C + s * (R + height); r.sat.orientation = r.q0; r.sat.scale = .init(repeating: scale)
        r.flare = Fx(.radial, hex, billboard: true, parent: r.sat); r.flare.e.position = [0, -0.5, 0.1]; r.flare.show(0.6)
        world.addChild(r.sat)
        r.core = Fx(.ribbon, hex, mesh: GlowKit.chunk(psi: psi, width: 0.1, dTheta: 2 * .pi / Float(SEGS)), count: SEGS, parent: world)
        r.halo = Fx(.ribbon, hex, mesh: GlowKit.chunk(psi: psi, width: 0.45, dTheta: 2 * .pi / Float(SEGS)), count: SEGS, parent: world)
        for (j, (c, h)) in zip(r.core.ents, r.halo.ents).enumerated() {
            let q = r.q0 * simd_quatf(angle: Float(j) / Float(SEGS) * 2 * .pi, axis: [0, 1, 0])
            c.position = C; c.orientation = q; h.position = C; h.orientation = q
        }
        r.core.setLevel(0.95); r.halo.setLevel(0.4)
        r.head = Fx(.radial, hex, billboard: true, parent: world); r.head.e.scale = .init(repeating: 0.9)
        return r
    }
    private func reveal(_ r: RingRig, _ frac: Float, _ lvl: Float) {
        r.core.setLevel(0.95 * lvl); r.halo.setLevel(0.4 * lvl)
        let c = lvl > 0.02 ? Int(frac * Float(SEGS)) : 0
        if c != r.shown { for j in 0..<SEGS { r.core.ents[j].isEnabled = j < c; r.halo.ents[j].isEnabled = j < c }; r.shown = c }
        if frac > 0.001 && frac < 0.999 && lvl > 0.5 { r.head.e.position = r.point(frac * 2 * .pi, R + 0.1, c: C); r.head.show(0.9) } else { r.head.hide() }
    }

    private func buildRing() {
        let r = newRing(psi: 0.5, s: [0, 1, 0], hex: 0x5aa9ff, height: 6.4, scale: 0.6)
        rigs = [r]
        var best: Float = -9
        for k in 0..<72 { let th = Float(k) / 72 * 2 * .pi; let z = r.point(th, R, c: C).z; if z > best { best = z; labelTheta = th } }
        dot = model(.generateSphere(radius: 0.1), glow(0xffe3d6)); world.addChild(dot)
        dotGlow = Fx(.radial, 0xff6b4a, billboard: true, parent: dot); dotGlow.e.scale = .init(repeating: 1.5)
        for _ in 0..<5 { dotTrail.append(Fx(.radial, 0xff6b4a, billboard: true, parent: world)) }
    }

    private func buildCross() {
        let defs: [(Float, Float, UInt32)] = [(0.34, 150 * .pi / 180, 0x5aa9ff), (0.31, 30 * .pi / 180, 0x5ee0a0), (0.36, 270 * .pi / 180, 0xff7ad9)]
        for d in defs { rigs.append(newRing(psi: d.0, s: [sin(d.0) * cos(d.1), cos(d.0), sin(d.0) * sin(d.1)], hex: d.2, height: 1.3, scale: 0.0001)) }
        let P: SIMD3<Float> = [0, 1, 0]
        let n = simd_normalize(simd_cross(rigs[0].s, rigs[1].s))
        mirror = P - 2 * simd_dot(P, n) * n
        markYou = model(.generateSphere(radius: 0.09), glow(0xffffff), at: C + P * (R + 0.1)); markMirror = model(.generateSphere(radius: 0.09), glow(0xffffff), at: C + mirror * (R + 0.1))
        markYouG = Fx(.radial, 0xffffff, billboard: true, parent: markYou); markYouG.e.scale = .init(repeating: 1.1)
        markMirrorG = Fx(.radial, 0xffffff, billboard: true, parent: markMirror); markMirrorG.e.scale = .init(repeating: 1.1)
        markYouG.show(0.7); markMirrorG.show(0.7)
        world.addChild(markYou); world.addChild(markMirror)
        let pm = SimpleMaterial(color: UIColor(hex: 0xff6b4a), roughness: 0.5, isMetallic: false)
        pin.addChild(model(.generateSphere(radius: 0.2), pm, at: [0, 0.74, 0]))
        let tip = model(.generateCone(height: 0.48, radius: 0.13), pm, at: [0, 0.24, 0]); tip.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0]); pin.addChild(tip)
        world.addChild(pin)
        ripple = Fx(.ribbon, 0xff9a80, mesh: GlowKit.annulus, parent: world)
    }

    private func buildStars() {
        if mode == 1 { return }
        for i in 0..<110 {
            let m = model(.generateSphere(radius: Float.random(in: 0.012...0.04)), glow(i % 9 == 0 ? 0xffe3a8 : 0xffffff))
            m.position = [Float.random(in: -14...14), Float.random(in: -1...17), -14]
            world.addChild(m); stars.append((m, Float.random(in: 0...6.28)))
        }
        for i in 0..<90 {   // below the globe, seen from above in cards 4 and 5
            let m = model(.generateSphere(radius: Float.random(in: 0.015...0.05)), glow(i % 9 == 0 ? 0xffe3a8 : 0xffffff))
            m.position = [Float.random(in: -12...12), -14, Float.random(in: -12...12)]
            starsTop.addChild(m)
        }
        world.addChild(starsTop); starsTop.isEnabled = mode >= 3
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

    func update(_ dt: Float) {
        guard built else { return }
        let drift: Float = reduce ? 0 : 1
        var lbls: [SceneLabel] = [], clk: ClockInfo? = nil

        // camera
        switch mode {
        case 0, 2:
            camPos = [sin(now * 0.1) * 0.3 * drift, 3.8, 12.5]; camTarget = [0, 3.6, 0]
        case 1:
            camPos = [-1.1 + sin(now * 0.1) * 0.2 * drift, 2.9, 13.2]; camTarget = [-1.1, 2.0, 0]
        case 3:   // the swing: orbit up and over the globe (pivot = the point under the satellite)
            let pb = smooth(0.5, 3.4, t), e = mix(atan2(3.8, 12.5), atan2(14.5, 1.4), pb), r = mix(13.06, 14.57, pb)
            camPos = [0, sin(e) * r, cos(e) * r]; camTarget = mix3([0, 3.6, 0], [0, 0, 0], pb)
        default:
            camPos = [0, 14.5, 1.4]; camTarget = .zero
        }
        camera.look(at: camTarget, from: camPos, relativeTo: nil)
        let camQ = camera.orientation(relativeTo: nil)
        for e in facing { e.setOrientation(camQ, relativeTo: nil) }
        for s in stars { s.e.scale = .init(repeating: 0.8 + 0.25 * sin(now * 1.6 + s.ph)) }

        switch mode {
        case 0: lbls = runListen()
        case 1: (lbls, clk) = runStorm()
        case 2: (lbls, clk) = runThunder()
        case 3: lbls = runRing()
        default: lbls = runCross()
        }
        if labels != lbls { labels = lbls }
        if clock != clk { clock = clk }
    }

    // MARK: card 1: it only listens

    private func runListen() -> [SceneLabel] {
        let period: Float = 3.6, offs: [Float] = [0.3, 1.5, 2.7]
        var lbls: [SceneLabel] = []
        var hit: Float = 0, lis: Float = 0
        for i in 0..<3 {
            let root = sats[i].root
            root.position = satBase[i] + [0, sin(now * 0.5 + Float(i) * 2) * 0.05, 0]
            root.orientation = simd_quatf(angle: sin(now * 0.3 + Float(i)) * 0.05, axis: [0, 0, 1])
            let a = satTip(i)
            let k: Float = t < offs[i] ? -1 : (t - offs[i]).truncatingRemainder(dividingBy: period)
            beams[i].aim(a, phoneW, cam: camPos, o: 0.4 * ramp(t, offs[i] - 0.2, offs[i] + 0.6), now: now, phase: Float(i) * 2)
            // shout: two soft rings expand in every direction from the satellite
            let sh = shout[i]
            for (j, ring) in sh.ents.enumerated() {
                let kk = (k - Float(j) * 0.4) / 2.3
                if k < 0 || kk <= 0 || kk >= 1 { ring.isEnabled = false; continue }
                ring.isEnabled = true; ring.position = a + [0, 0.1, 0]; ring.scale = .init(repeating: 0.12 + 2.3 * (1 - pow(1 - kk, 2)))
            }
            let kr = max(0, min(0.99, k / 2.3))
            sh.setLevel(k < 0 || k > 2.3 ? 0 : 0.85 * (1 - kr) + 0.1)
            // flare at the satellite when it shouts
            let burst: Float = k >= 0 ? exp(-k * 3) : 0
            sats[i].flare.e.scale = .init(repeating: 1.0 + 2.0 * burst); sats[i].flare.show(0.5 + 0.5 * burst)
            // a pulse drops from the satellite to the listener
            let kp = (k - 0.15) / 1.4
            if k >= 0 && kp > 0 && kp < 1 {
                let p = mix3(a, phoneW, kp), d = simd_normalize(phoneW - a)
                placeAlong(comet[i].outer.e, from: p - d * 0.7, to: p + d * 0.1, width: 0.5, cam: camPos); comet[i].outer.show(0.9)
                placeAlong(comet[i].inner.e, from: p - d * 0.3, to: p + d * 0.05, width: 0.16, cam: camPos); comet[i].inner.show(1)
            } else { comet[i].outer.hide(); comet[i].inner.hide() }
            if k >= 1.55 && k < 2.4 { hit = max(hit, 1 - (k - 1.55) / 0.85) }
            if k >= 0.95 && k < 1.6 { lis = ramp(k, 0.95, 1.6) }
            // clock stamp "12:00:00" on each shout
            let o = k < 0 ? 0 : smooth(0, 0.18, k) * (1 - smooth(1.9, 2.5, k))
            lbls.append(label("clk\(i)", "12:00:00", at: a, dy: 40, o))
        }
        flareAt(hit, base: 0.25); listen(lis); ground(0, 0)
        lbls.append(label("hear", "Just listening", at: phoneW, dx: 78, dy: 30, smooth(2.0, 2.6, t)))
        return lbls
    }

    // MARK: card 2: late boom, far storm

    private func runStorm() -> ([SceneLabel], ClockInfo?) {
        let T: Float = 11.2, ph = t.truncatingRemainder(dividingBy: T), f = 1 - ramp(ph, 10.5, 11.1)
        let fs: Float = 1.2, dt = ph - fs
        var I: Float = 0
        if dt >= 0 { if dt < 0.1 { I = 1 } else if dt < 0.16 { I = 0.7 } else if dt < 0.36 { I = 1 } else { I = max(0.45 * (1 - (dt - 0.36) / 0.8), 0) + 0 } }
        let bright = I > 0.45
        if bright != cloudIsBright { cloudIsBright = bright; for c in cloudParts { c.model?.materials = [bright ? cloudBright : cloudDark] } }
        sunL.light.intensity = 1300 + 3800 * I
        skyGlow.show(0.5 * I)
        for s in bolt {
            placeAlong(s.core.e, from: s.a, to: s.b, width: 0.13 * (0.5 + 0.5 * I), cam: camPos); s.core.show(I)
            placeAlong(s.halo.e, from: s.a, to: s.b, width: 0.6 * (0.5 + 0.5 * I), cam: camPos); s.halo.show(0.65 * I)
        }
        // rain
        for r in rain {
            let k = (now * r.sp * 0.5 + r.ph).truncatingRemainder(dividingBy: 1), y = 4.2 - k * 5.2
            r.f.e.isEnabled = true; r.f.e.position = [r.x + (4.2 - y) * 0.1, y, 0.3]
            r.f.e.orientation = simd_quatf(angle: 0.1, axis: [0, 0, 1]); r.f.e.scale = [0.025, 0.55, 1]
        }
        // sound wave crawls from the strike across the ground to the person
        let ws: Float = 1.6, wd: Float = 3.2, pa = ws + wd, pr = (ph - ws) / wd
        let D = personPos.x - boltBase.x
        waveRings.setLevel(0.9 * f)
        for (i, ring) in waveRings.ents.enumerated() {
            let p = pr - Float(i) * 0.1
            if ph < ws || p <= 0 || p >= 1.3 || f < 0.05 { ring.isEnabled = false; continue }
            ring.isEnabled = true
            ring.position = [boltBase.x, boltBase.y + 0.05 + (personPos.y - boltBase.y) * min(p, 1), 0.1]; ring.scale = [D * p, D * p * 0.5, 1]
        }
        let rA = ph - pa
        flareAt(rA >= 0 ? 1 - ramp(rA, 0, 1.3) : 0, base: 0.2 * 0)
        if rA < 0 { phoneFlare.hide() }
        listen(rA >= -0.4 && rA < 0.4 ? ramp(rA, -0.4, 0.4) : 0)
        ground(ramp(rA, 0, 1.5), rA >= 0 ? 0.6 * (1 - ramp(rA, 0, 1.5)) * f : 0)
        // bracket: 3 s = about 1 km
        let bk = smooth(6.2, 6.9, ph) * f, by: Float = 2.5, x0 = boltBase.x, x1 = personPos.x
        if bk > 0.04 {
            placeAlong(bracket[0].e, from: [x0, by, 0], to: [x1, by, 0], width: 0.04, cam: camPos)
            placeAlong(bracket[1].e, from: [x0, by - 0.3, 0], to: [x0, by + 0.3, 0], width: 0.04, cam: camPos)
            placeAlong(bracket[2].e, from: [x1, by - 0.3, 0], to: [x1, by + 0.3, 0], width: 0.04, cam: camPos)
            bracket.forEach { $0.show(0.9 * bk) }
        } else { bracket.forEach { $0.hide() } }
        var l: [SceneLabel] = []
        l.append(label("flash", "Flash", at: [boltBase.x, 3.0, 0], dx: 52, dy: 0, ramp(ph, fs, fs + 0.1) * (1 - ramp(ph, fs + 0.8, fs + 1.1)) * f))
        l.append(label("boom", "Boom, 3 s later", at: personPos + up * 1.7, dy: -6, ramp(ph, pa, pa + 0.25) * f))
        l.append(label("km", "3 s = about 1 km", at: [(x0 + x1) / 2, by, 0], bk))
        let sec = ph < fs ? 0 : min(1, max(0, pr)) * 3.0
        return (l, ph >= fs ? ClockInfo(title: "Seconds since flash", text: String(format: "%.1f s", sec), opacity: Double(f)) : nil)
    }

    // MARK: card 3: very fast thunderclap

    private func runThunder() -> ([SceneLabel], ClockInfo?) {
        let T: Float = 10.5, ph = t.truncatingRemainder(dividingBy: T), f = 1 - ramp(ph, 9.6, 10.2)
        let fs: Float = 0.5
        let root = sats[0].root
        root.position = satBase[0] + [0, sin(now * 0.5) * 0.04, 0]; root.orientation = .init(angle: 0, axis: [0, 0, 1])
        let a = satTip(0), d = simd_normalize(phoneW - a), len = simd_length(phoneW - a)
        let burst: Float = ph >= fs ? exp(-(ph - fs) * 3) : 0
        sats[0].flare.e.scale = .init(repeating: 1.0 + 2.2 * burst); sats[0].flare.show(0.5 + 0.5 * burst)
        beams[0].aim(a, phoneW, cam: camPos, o: 0.35 * ramp(ph, fs, fs + 0.7) * f, now: now)
        let k = ramp(ph, 1.4, 3.4), fly = k > 0 && k < 1
        pulseCore.isEnabled = ph >= fs && f > 0.02
        pulseCore.position = a + d * len * k
        pulseCore.scale = .init(repeating: (k >= 1 ? 1 + 0.2 * sin(now * 9) : 1) * max(0.01, f))
        pulseFlare.show(0.9 * f)
        for (i, tr) in trail.enumerated() {
            if fly {
                let p = a + d * len * max(0, k - Float(i) * 0.035)
                placeAlong(tr.e, from: p - d * 0.4, to: p, width: 0.42 - Float(i) * 0.06, cam: camPos); tr.show(0.7 - Float(i) * 0.1)
            } else { tr.hide() }
        }
        let rA = ph - 3.4
        flareAt(rA >= 0 ? (0.6 + 0.4 * sin(now * 8)) * (1 - ramp(rA, 0.5, 5)) * f + 0.15 * f : 0)
        if rA < 0 { phoneFlare.hide() }
        if f < 0.05 { phoneFlare.hide() }
        listen(rA >= -0.5 && rA < 0.3 ? ramp(rA, -0.5, 0.3) : 0)
        ground(ramp(rA, 0, 1.5), rA >= 0 && rA < 1.5 ? 0.6 * (1 - ramp(rA, 0, 1.5)) * f : 0)
        // measuring line, left of the beam
        let dk = smooth(4.7, 5.5, ph) * f, lx: Float = -1.75
        if dk > 0.04 {
            let A: SIMD3<Float> = [lx, a.y, 0], B: SIMD3<Float> = [lx, phoneW.y, 0]
            placeAlong(dimLine[0].e, from: A, to: B, width: 0.04, cam: camPos)
            placeAlong(dimLine[1].e, from: A + [-0.25, 0, 0], to: A + [0.25, 0, 0], width: 0.04, cam: camPos)
            placeAlong(dimLine[2].e, from: B + [-0.25, 0, 0], to: B + [0.25, 0, 0], width: 0.04, cam: camPos)
            dimLine.forEach { $0.show(0.9 * dk) }
        } else { dimLine.forEach { $0.hide() } }
        var l: [SceneLabel] = []
        l.append(label("sent", "Sent 0.00 s", at: a, dx: 86, dy: -2, smooth(fs, fs + 0.3, ph) * f))
        l.append(label("lands", "Lands 0.07 s", at: phoneW, dx: 88, dy: -2, smooth(3.4, 3.7, ph) * f))
        l.append(label("dist", "About 20,200 km", at: [lx, (a.y + phoneW.y) / 2, 0], dk))
        return (l, ph >= fs ? ClockInfo(title: "Clock since sent", text: String(format: "%.2f s", 0.07 * k), opacity: Double(f)) : nil)
    }

    // MARK: card 4: one distance, one ring

    private func runRing() -> [SceneLabel] {
        let r = rigs[0], pb = smooth(0.5, 3.4, t)
        let H = mix(6.4, 3.4, pb)
        r.sat.position = C + r.s * (R + H)
        // the street scene shrinks away as the camera rises
        let sc = 1 - smooth(0.8, 2.0, t)
        local.scale = .init(repeating: max(0.001, sc)); local.isEnabled = sc > 0.01
        let ring = ramp(t, 2.6, 4.6)
        r.beacon.scale = .init(repeating: 0.8 + 0.4 * sin(now * 6))
        let burst: Float = t > 2.6 ? exp(-(t - 2.6) * 2.5) : 0
        r.flare.e.scale = .init(repeating: 1 + 1.6 * burst); r.flare.show(0.5 + 0.5 * burst)
        reveal(r, ring, 1)
        flareAt(0); phoneFlare.hide(); phoneGlow.components.set(PointLightComponent(color: UIColor(hex: 0x9fe6ff), intensity: 3000 * sc, attenuationRadius: 2.5))
        beams.forEach { $0.hide() }
        // a dot circling the ring: you could be anywhere on it
        let dk = smooth(4.6, 5.2, t)
        let th = (t - 4.6) * 0.9
        let p = r.point(th, R + 0.14, c: C)
        dot.isEnabled = dk > 0.02; dot.position = p; dot.scale = .init(repeating: dk)
        dotGlow.show(0.9 * dk)
        for (i, d) in dotTrail.enumerated() {
            d.e.position = r.point(th - Float(i + 1) * 0.1, R + 0.12, c: C); d.e.scale = .init(repeating: 0.55 - Float(i) * 0.09); d.show(dk * (0.6 - Float(i) * 0.1))
        }
        return [label("any", "Anywhere on this ring", at: r.point(labelTheta, R, c: C), dy: 30, smooth(4.9, 5.5, t))]
    }

    // MARK: card 5: rings meet at one spot

    private func runCross() -> [SceneLabel] {
        let total: Float = 13.4, ph = t.truncatingRemainder(dividingBy: total), f = 1 - ramp(ph, total - 0.9, total - 0.1)
        let ins: [Float] = [0.4, 2.0, 5.6], sweepDur: Float = 1.5
        for (i, r) in rigs.enumerated() {
            let sIn = smooth(ins[i], ins[i] + 0.6, ph) * f
            r.sat.scale = .init(repeating: max(0.0001, 0.55 * sIn)); r.sat.isEnabled = sIn > 0.01
            r.beacon.scale = .init(repeating: 0.8 + 0.4 * sin(now * 6 + Float(i)))
            let sw = ramp(ph, ins[i] + 0.5, ins[i] + 0.5 + sweepDur)
            reveal(r, smooth(0, 1, sw), f)
            let burst: Float = ph > ins[i] + 0.5 ? exp(-(ph - ins[i] - 0.5) * 2.5) : 0
            r.flare.e.scale = .init(repeating: 1 + 1.4 * burst); r.flare.show((0.5 + 0.5 * burst) * sIn)
        }
        let two = ins[1] + 0.5 + sweepDur, lastDone = ins[2] + 0.5 + sweepDur
        let pk = 0.85 + 0.3 * sin(now * 7)
        let youK = ph > two ? 1 : 0, missK = 1 - ramp(ph, lastDone, lastDone + 1.0)
        markYou.isEnabled = ph > two && f > 0.02; markMirror.isEnabled = ph > two && missK > 0.01 && f > 0.02
        markYou.scale = .init(repeating: pk * f * Float(youK)); markMirror.scale = .init(repeating: pk * missK * f)
        // pin lands on the spot that fits all three
        let pinAt = lastDone + 0.9
        let pinK = smooth(pinAt, pinAt + 0.6, ph) * f
        pin.isEnabled = pinK > 0.001; pin.scale = .init(repeating: max(0.001, pinK))
        pin.position = [0, 0.06 + (1 - pinK) * 1.6 + sin(now * 3) * 0.02, 0]
        if pinK > 0.9 { markYou.isEnabled = false }
        let gk = max(0, (ph - pinAt - 0.5).truncatingRemainder(dividingBy: 1.4)) / 1.4
        if pinK > 0.9 {
            ripple.e.position = [0, 0.1, 0]; ripple.e.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            ripple.e.scale = .init(repeating: 0.25 + gk * 1.1); ripple.show((1 - gk) * 0.7 * f)
        } else { ripple.hide() }
        var l: [SceneLabel] = []
        l.append(label("two", "Two spots", at: C + mirror * (R + 0.1), dy: -26, smooth(two, two + 0.4, ph) * (1 - ramp(ph, ins[2], ins[2] + 0.4)) * f))
        l.append(label("miss", "Misses", at: C + mirror * (R + 0.1), dy: -26, smooth(lastDone, lastDone + 0.3, ph) * (1 - ramp(ph, lastDone + 0.9, lastDone + 1.4)) * f))
        l.append(label("you", "You", at: [0, 1.75, 0], dy: -8, ramp(ph, pinAt + 0.3, pinAt + 0.7) * f, you: true))
        return l
    }
}

private extension ModelEntity {
    func also(_ f: (ModelEntity) -> Void) -> ModelEntity { f(self); return self }
}
