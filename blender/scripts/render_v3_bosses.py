"""Render V3 boss portrait silhouettes from the existing fighter rig + custom boss modifications.
Uses composite primitives to create distinct, menacing boss profiles.
Blender 4.0.2 headless."""
import bpy, math
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "blender" / "v3"
OUT_DIR.mkdir(parents=True, exist_ok=True)

def clear_all():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        if block.users == 0: bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0: bpy.data.materials.remove(block)

def setup_scene(res=320):
    s = bpy.context.scene
    s.render.engine = 'BLENDER_EEVEE'
    s.eevee.taa_render_samples = 64
    s.render.resolution_x = res
    s.render.resolution_y = res
    s.render.resolution_percentage = 100
    s.render.film_transparent = True
    s.render.image_settings.file_format = 'PNG'
    s.render.image_settings.color_mode = 'RGBA'
    s.view_settings.view_transform = 'Standard'

def add_camera(loc=(0, -3.5, 0.7), scale=1.8):
    bpy.ops.object.camera_add(location=loc, rotation=(math.radians(90), 0, 0))
    cam = bpy.context.object
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    bpy.context.scene.camera = cam
    return cam

def mat(name, r, g, b):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes; n.clear()
    out = n.new('ShaderNodeOutputMaterial')
    emit = n.new('ShaderNodeEmission')
    emit.inputs[0].default_value = (r, g, b, 1.0)
    m.node_tree.links.new(emit.outputs[0], out.inputs[0])
    return m

def sphere(loc, radius, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=radius, location=loc)
    o = bpy.context.object; o.data.materials.append(material)
    for p in o.data.polygons: p.use_smooth = True
    return o

def cylinder(loc, radius, depth, material, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object; o.data.materials.append(material)
    for p in o.data.polygons: p.use_smooth = True
    return o

def cone(loc, r1, r2, depth, material, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object; o.data.materials.append(material)
    for p in o.data.polygons: p.use_smooth = True
    return o

def cube(loc, size, material, scale=(1,1,1)):
    bpy.ops.mesh.primitive_cube_add(size=size, location=loc)
    o = bpy.context.object; o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    return o

def torus(loc, major, minor, material, rot=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=loc, rotation=rot)
    o = bpy.context.object; o.data.materials.append(material)
    for p in o.data.polygons: p.use_smooth = True
    return o

# ─────── WARDEN GURO: Chapter 1 Boss ───────
# Concept: Bulky prison warden, iron kabuto helmet, heavy ji (halberd).
# Silhouette: Broad shoulders, armored pauldrons, crescent crest, thick limbs.

def build_boss_guro():
    clear_all()
    setup_scene(320)
    add_camera(loc=(0, -3.5, 0.72), scale=1.9)

    ink = mat("ink", 0.008, 0.010, 0.018)
    steel = mat("steel", 0.12, 0.13, 0.15)
    gold = mat("gold_crest", 0.82, 0.62, 0.18)

    # Legs — thick stance
    cylinder((-0.12, 0, 0.25), 0.07, 0.45, ink)  # left thigh
    cylinder((0.12, 0, 0.25), 0.07, 0.45, ink)   # right thigh
    sphere((-0.12, 0, 0.05), 0.075, ink)  # left foot
    sphere((0.12, 0, 0.05), 0.075, ink)   # right foot
    # Pelvis + wide armored torso
    cylinder((0, 0, 0.52), 0.15, 0.08, ink)  # pelvis
    cylinder((0, 0, 0.72), 0.22, 0.42, ink)  # torso
    # Pauldrons (shoulder armor ridges)
    sphere((-0.28, 0, 0.88), 0.11, steel)
    sphere((0.28, 0, 0.88), 0.11, steel)
    cone((-0.28, 0, 0.98), 0.08, 0.02, 0.12, steel)  # spike left
    cone((0.28, 0, 0.98), 0.08, 0.02, 0.12, steel)   # spike right
    # Neck
    cylinder((0, 0, 0.96), 0.08, 0.06, ink)
    # Iron kabuto head
    sphere((0, 0, 1.08), 0.15, ink)  # skull
    # Kabuto brim (flat disc)
    cylinder((0, 0, 1.02), 0.22, 0.02, steel)
    # Crescent maedate crest
    torus((0, 0, 1.22), 0.14, 0.025, gold, rot=(math.radians(90), 0, 0))
    # Arms — thick
    cylinder((-0.30, 0, 0.68), 0.065, 0.35, ink, rot=(0, 0, math.radians(10)))  # left arm
    cylinder((0.35, 0, 0.72), 0.065, 0.40, ink, rot=(0, 0, math.radians(-8)))   # right arm (weapon arm)
    sphere((-0.32, 0, 0.50), 0.055, ink)  # left fist
    # Ji Halberd — long weapon in right hand
    cylinder((0.42, 0, 0.70), 0.025, 1.30, ink)  # shaft
    # Halberd crescent blade at top
    torus((0.42, 0, 1.32), 0.10, 0.018, steel, rot=(0, math.radians(90), 0))
    cone((0.42, 0, 1.38), 0.06, 0.01, 0.12, steel)  # spear tip

    bpy.context.scene.render.filepath = str(OUT_DIR / "boss_guro.png")
    bpy.ops.render.render(write_still=True)
    print("✓ boss_guro.png")

# ─────── MADAME LIN: Chapter 2 Boss ───────
# Concept: Elegant, lethal assassin. Twin kama blades, veiled head, flowing ribbons.
# Silhouette: Slim, poised, asymmetric stance, twin curved weapons.

def build_boss_lin():
    clear_all()
    setup_scene(320)
    add_camera(loc=(0, -3.5, 0.72), scale=1.85)

    ink = mat("ink", 0.008, 0.010, 0.018)
    silk = mat("silk", 0.55, 0.05, 0.22)   # deep crimson sash
    cyan = mat("cyan_edge", 0.05, 0.75, 0.90)

    # Legs — elegant stance, one slightly forward
    cylinder((-0.09, 0, 0.24), 0.05, 0.44, ink, rot=(0, 0, math.radians(3)))
    cylinder((0.11, 0, 0.22), 0.05, 0.40, ink, rot=(0, 0, math.radians(-5)))
    sphere((-0.10, 0, 0.03), 0.055, ink)
    sphere((0.14, 0, 0.03), 0.055, ink)
    # Slim torso
    cylinder((0, 0, 0.50), 0.10, 0.06, ink)  # waist
    cone((0, 0, 0.72), 0.14, 0.10, 0.38, ink)  # tapered torso
    # Sash ribbon across waist
    cylinder((0, 0, 0.53), 0.12, 0.03, silk)
    # Trailing ribbon end
    cube((0.18, 0, 0.42), 0.06, silk, scale=(0.5, 0.2, 2.5))
    # Neck and veiled head
    cylinder((0, 0, 0.94), 0.05, 0.04, ink)
    sphere((0, 0, 1.04), 0.12, ink)  # head
    # Veil draping (thin triangle below chin)
    cone((0, 0.04, 0.92), 0.10, 0.04, 0.08, ink)
    # Hair ornament pin
    cylinder((0.06, 0, 1.14), 0.012, 0.20, cyan, rot=(0, 0, math.radians(25)))
    sphere((0.10, 0, 1.22), 0.025, cyan)  # pin head
    # Arms — graceful extension
    cylinder((-0.18, 0, 0.78), 0.04, 0.30, ink, rot=(0, 0, math.radians(20)))
    cylinder((0.18, 0, 0.76), 0.04, 0.32, ink, rot=(0, 0, math.radians(-18)))
    # Twin Kama — curved blade weapons
    for side in [-1, 1]:
        x = side * 0.32
        # Handle
        cylinder((x, 0, 0.58), 0.018, 0.26, ink, rot=(0, 0, side * math.radians(15)))
        # Curved blade (torus arc)
        torus((x + side*0.08, 0, 0.68), 0.10, 0.015, cyan, rot=(math.radians(90), 0, side * math.radians(30)))

    bpy.context.scene.render.filepath = str(OUT_DIR / "boss_lin.png")
    bpy.ops.render.render(write_still=True)
    print("✓ boss_lin.png")

# ─────── GENERAL KUROZUKA: Chapter 3 Final Boss ───────
# Concept: Warlord general, massive oni-horned helm, two-handed nodachi greatsword.
# Silhouette: Imposing, broad, demon horns, flowing cape, enormous blade.

def build_boss_kurozuka():
    clear_all()
    setup_scene(320)
    add_camera(loc=(0, -3.5, 0.76), scale=2.1)

    ink = mat("ink", 0.008, 0.010, 0.018)
    fire = mat("fire", 0.95, 0.28, 0.08)    # demon-horn accent
    crimson = mat("crimson", 0.72, 0.06, 0.12)  # cape

    # Legs — wide powerful base
    cylinder((-0.15, 0, 0.25), 0.08, 0.46, ink, rot=(0, 0, math.radians(5)))
    cylinder((0.15, 0, 0.25), 0.08, 0.46, ink, rot=(0, 0, math.radians(-5)))
    sphere((-0.17, 0, 0.04), 0.08, ink)
    sphere((0.17, 0, 0.04), 0.08, ink)
    # Massive armored torso
    cylinder((0, 0, 0.54), 0.18, 0.10, ink)  # waist
    cylinder((0, 0, 0.78), 0.26, 0.48, ink)  # armored chest
    # Layered shoulder plates
    for side in [-1, 1]:
        cylinder((side * 0.30, 0, 0.95), 0.10, 0.06, ink)
        cylinder((side * 0.30, 0, 0.90), 0.13, 0.03, ink)
    # Cape — draping from shoulders
    cone((0, 0.06, 0.60), 0.30, 0.08, 0.65, crimson)
    # Neck
    cylinder((0, 0, 1.00), 0.08, 0.06, ink)
    # Oni-horned kabuto
    sphere((0, 0, 1.14), 0.17, ink)  # head
    cylinder((0, 0, 1.06), 0.24, 0.03, ink)  # kabuto brim
    # Fierce oni horns
    cone((-0.16, 0, 1.30), 0.055, 0.015, 0.38, fire, rot=(0, 0, math.radians(25)))
    cone((0.16, 0, 1.30), 0.055, 0.015, 0.38, fire, rot=(0, 0, math.radians(-25)))
    # Menpo face guard (partial sphere)
    sphere((0, -0.06, 1.08), 0.10, ink)
    # Arms — thick armored
    cylinder((-0.32, 0, 0.72), 0.07, 0.38, ink, rot=(0, 0, math.radians(12)))
    cylinder((0.34, 0, 0.74), 0.07, 0.40, ink, rot=(0, 0, math.radians(-10)))
    # Nodachi Greatsword — enormous two-handed blade
    cylinder((0.42, 0, 0.75), 0.028, 1.50, ink)  # shaft
    # Long blade
    cube((0.42, 0, 1.42), 0.08, ink, scale=(0.5, 0.12, 4.5))
    # Blade tip
    cone((0.42, 0, 1.68), 0.04, 0.005, 0.12, ink)
    # Tsuba guard
    cylinder((0.42, 0, 1.15), 0.06, 0.015, fire)

    bpy.context.scene.render.filepath = str(OUT_DIR / "boss_kurozuka.png")
    bpy.ops.render.render(write_still=True)
    print("✓ boss_kurozuka.png")


if __name__ == "__main__":
    build_boss_guro()
    build_boss_lin()
    build_boss_kurozuka()
    print("All V3 boss silhouettes rendered!")
