"""GnomiT Grok task-003 - independent storybook environment challenger generator.
Run: blender -b --python grok_build_environment.py -- <input airy_island.glb> <out.blend> <out.glb>
Keeps from the current map only: Portrait_Camera, Road_Centerline (+route extras),
Level_1/2_Anchor, the Mushroom_Cottage hierarchy. Everything else is rebuilt.
All artistic parameters live in PARAMS so the scene stays procedurally editable."""
import bpy, bmesh, json, math, random, sys
from mathutils import Vector, Matrix, noise

PARAMS = dict(
    seed=3003,
    island=dict(a=3.9, b=10.3, n=2.15, lobe=0.04, top_z=0.78, lip_drop=0.16,
                earth_rings=[(0.62,1.0),(0.2,1.006),(-0.7,0.985),(-1.7,0.93),(-2.6,0.8),(-3.3,0.58)],
                bottom_wave=0.35),
    path=dict(half_width=0.64, plank_pitch=0.40, gap=0.022, thickness=0.11, curb_radius=0.075,
              post_every=6, post_radius=0.13),
    tree=dict(crown_scale=1.45),
    grass=dict(min_path_clear=1.05, blades=(12,16)),
)
P = PARAMS
argv = sys.argv[sys.argv.index('--')+1:]
SRC, OUT_BLEND, OUT_GLB = argv
random.seed(P['seed'])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
KEEP_ROOTS = {'Portrait_Camera','Road_Centerline','Level_1_Anchor','Level_2_Anchor','Mushroom_Cottage'}
keep = set()
for n in KEEP_ROOTS:
    o = bpy.data.objects[n]; keep.add(o); keep.update(o.children_recursive)
old_root = bpy.data.objects['GnomiT_Airy_Island_v001']
keep.add(old_root)
for o in list(bpy.data.objects):
    if o not in keep: bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    if m.users == 0: bpy.data.meshes.remove(m)
old_root.name = 'GnomiT_Grok_Island_T003'
ROOT = old_root
COL = bpy.context.scene.collection
route = [Vector(p) for p in json.loads(bpy.data.objects['Road_Centerline']['sample_points_json'])]

# ---------- materials (matte storybook, no gloss) ----------
MATS = {}
def mat(name, hexc, rough=0.85, emit=None, emit_str=0.0, double=False):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new('Grok_'+name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    c = tuple(int(hexc[i:i+2],16)/255 for i in (0,2,4))
    lin = tuple(((x+0.055)/1.055)**2.4 if x>0.04045 else x/12.92 for x in c)
    b.inputs['Base Color'].default_value = (*lin,1)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Specular IOR Level'].default_value = 0.25
    if emit:
        e = tuple(int(emit[i:i+2],16)/255 for i in (0,2,4))
        b.inputs['Emission Color'].default_value = (*e,1); b.inputs['Emission Strength'].default_value = emit_str
    m.use_backface_culling = not double
    MATS[name] = m; return m
G_GROUND = mat('Meadow_Ground','67b53f',0.95)
G_LIP = mat('Meadow_Lip','5aa437',0.95)
G_TUFT = mat('Grass_Tuft','82c94b',0.9,double=True)
G_TUFT_D = mat('Grass_Tuft_Deep','5c9f35',0.9,double=True)
E_TOP = mat('Earth_Topsoil','8a5530',0.95)
E_MID = mat('Earth_Warm','c98545',0.95)
E_LOW = mat('Earth_Deep','a4643a',0.95)
W_DECK = mat('Wood_Honey','d99a52',0.8)
W_DARK = mat('Wood_Honey_Dark','a8682f',0.85)
W_POST = mat('Wood_Post','b97638',0.85)
W_END = mat('Wood_Endgrain','f0c27d',0.85)
BARK = mat('Bark','8c5a35',0.9)
LEAF = mat('Crown_Leaf','5fb23c',0.9)
LEAF_L = mat('Crown_Leaf_Light','8fcf4f',0.9)
STONE = mat('Stone','b8b1a4',0.9)
STONE_D = mat('Stone_Shadow','8f887d',0.9)
MOSS = mat('Moss','79bb42',0.95)
TUNNEL = mat('Mine_Dark_Interior','140c08',1.0)
IRON = mat('Lantern_Iron','3a3330',0.7)
LAMP = mat('Lantern_Glow','ffcf7a',0.6,emit='ffb04a',emit_str=1.2)
PINK = mat('Flower_Pink','f08cab',0.85); WHITE = mat('Flower_White','fbf6ea',0.85); YEL = mat('Flower_Centre','f6c843',0.85)

def obj_from_bm(name, bm, material=None, parent=ROOT, smooth=True):
    if len(bm.faces): bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name+'_Mesh'); bm.to_mesh(me); bm.free()
    if smooth:
        for f in me.polygons: f.use_smooth = True
    o = bpy.data.objects.new(name, me); COL.objects.link(o); o.parent = parent
    if material:
        if isinstance(material,(list,tuple)):
            for m in material: me.materials.append(m)
        else: me.materials.append(material)
    return o
def subsurf(o, lv=2):
    m = o.modifiers.new('Grok_Soft','SUBSURF'); m.levels = lv; m.render_levels = lv; return o
def empty(name, loc, parent=ROOT):
    e = bpy.data.objects.new(name, None); COL.objects.link(e); e.parent = parent; e.location = loc; return e

# ---------- route helpers ----------
def resample(pts, step):
    out=[pts[0]]; acc=0.0
    for a,b in zip(pts,pts[1:]):
        seg=(b-a).length; t=0
        while acc+seg-t >= step:
            t += step-acc; acc=0; out.append(a.lerp(b,t/seg))
        acc += seg-t
    return out
def path_dist(p):
    best=1e9
    for a,b in zip(route,route[1:]):
        ab=(b-a).xy; ap=(p.xy-a.xy); t=max(0,min(1,ap.dot(ab)/max(ab.length_squared,1e-9)))
        best=min(best,(a.xy+ab*t-p.xy).length)
    return best

# ---------- ISLAND ----------
I=P['island']
def outline(th, s=1.0, wave=0.0, phase=0.0):
    c,si=math.cos(th),math.sin(th)
    r = (abs(c/I['a'])**I['n']+abs(si/I['b'])**I['n'])**(-1/I['n'])
    r *= 1+I['lobe']*math.sin(5*th+0.7)+0.03*math.sin(11*th)+wave*math.sin(9*th+phase)
    return Vector((c*r*s, si*r*s))
N=96
def ring(bm, s, z, wave=0.0, zw=0.0, phase=0.0):
    vs=[]
    for i in range(N):
        th=2*math.pi*i/N; xy=outline(th,s,wave,phase)
        vs.append(bm.verts.new((xy.x,xy.y,z+zw*math.sin(7*th+phase))))
    return vs
def bridge(bm,r1,r2,mi=0):
    for i in range(N):
        f=bm.faces.new((r1[i],r1[(i+1)%N],r2[(i+1)%N],r2[i])); f.material_index=mi
# grass cap: gentle dome + rolled lip
bm=bmesh.new(); tz=I['top_z']
c=bm.verts.new((0,0,tz+0.05))
rings=[(0.35,tz+0.045),(0.7,tz+0.03),(0.9,tz+0.012),(0.975,tz),(1.0,tz-0.05),(1.012,tz-I['lip_drop']),(0.995,tz-0.24)]
prev=None
for k,(s,z) in enumerate(rings):
    r=ring(bm,s,z)
    if prev is None:
        for i in range(N): bm.faces.new((c,r[i],r[(i+1)%N]))
    else: bridge(bm,prev,r, 1 if k>=4 else 0)
    prev=r
cap=obj_from_bm('Grok_Island_Meadow_Cap',bm,[G_GROUND,G_LIP]); subsurf(cap,2)
# earth mass: three soft strata, tapering with lobed underside
bm=bmesh.new(); prev=None
er=I['earth_rings']
for k,(z,s) in enumerate(er):
    last = k==len(er)-1
    r=ring(bm,s,z, wave=0.05 if k>=3 else 0.0, zw=I['bottom_wave']*(k/len(er))**2, phase=1.3)
    if prev: bridge(bm,prev,r, 0 if k==1 else (1 if k<=3 else 2))
    prev=r
bot=bm.verts.new((0,0,er[-1][0]-0.45))
for i in range(N): f=bm.faces.new((prev[(i+1)%N],prev[i],bot)); f.material_index=2
earth=obj_from_bm('Grok_Island_Earth_Mass',bm,[E_TOP,E_MID,E_LOW]); subsurf(earth,2)

MEADOW_L=mat('Meadow_Sunlit','7cc447',0.95)
for k,(x,y,rx,ry) in enumerate(((-2.6,-0.9,0.95,1.4),(2.6,-2.8,0.9,1.3),(2.0,4.6,1.2,1.4),(-2.4,5.0,1.1,1.3),(0.9,-8.6,1.1,0.8))):
    bm=bmesh.new(); bmesh.ops.create_uvsphere(bm,u_segments=24,v_segments=12,radius=1.0)
    for v in bm.verts: v.co=Vector((x+v.co.x*rx,y+v.co.y*ry,I['top_z']-0.05+v.co.z*0.16))
    o=obj_from_bm('Grok_Meadow_Hillock_%d'%k,bm,MEADOW_L)
# ---------- PATH: one continuous crafted boardwalk ----------
Pp=P['path']; hw=Pp['half_width']
samples=resample(route, Pp['plank_pitch'])
def frame(i,pts):
    a=pts[max(0,i-1)]; b=pts[min(len(pts)-1,i+1)]
    t=(b-a); t.z=0; t.normalize(); n=Vector((-t.y,t.x,0)); return t,n
bm=bmesh.new()
for i,p in enumerate(samples):
    t,n=frame(i,samples)
    L=Pp['plank_pitch']-Pp['gap']; jitter=random.uniform(-0.03,0.03)
    wl=hw+random.uniform(-0.02,0.03); wr=hw+random.uniform(-0.02,0.03)
    top=p.z+0.005*random.uniform(-1,1); bz=top-Pp['thickness']
    corners=[]
    for z in (bz,top):
        for (u,v) in ((-L/2,-wr),(L/2,-wr),(L/2,wl),(-L/2,wl)):
            corners.append(bm.verts.new(p.xy.to_3d()+t*u+n*(v+jitter*0.3)+Vector((0,0,z-p.z+p.z))))
    for v in corners: v.co.z = v.co.z
    b0,b1,b2,b3,t0,t1,t2,t3=corners
    fs=[bm.faces.new(q) for q in ((b0,b3,b2,b1),(t0,t1,t2,t3),(b0,b1,t1,t0),(b1,b2,t2,t1),(b2,b3,t3,t2),(b3,b0,t0,t3))]
    ed=[e for f in fs for e in f.edges]
    bmesh.ops.bevel(bm, geom=list(set(ed)), offset=0.03, segments=2, affect='EDGES', profile=0.5)
deck=obj_from_bm('Grok_Boardwalk_Deck',bm,W_DECK)
# continuous under-stringer (reads as one object, fills gaps darkly)
def sweep(name, pts, offset, z_off, radius, material, flat=1.0):
    cu=bpy.data.curves.new(name+'_Curve','CURVE'); cu.dimensions='3D'
    sp=cu.splines.new('POLY'); sp.points.add(len(pts)-1)
    for i,p in enumerate(pts):
        t,n=frame(i,pts); q=p+n*offset+Vector((0,0,z_off)); sp.points[i].co=(*q,1)
    cu.bevel_depth=radius; cu.bevel_resolution=3; cu.use_fill_caps=True
    co=bpy.data.objects.new(name+'_Src',cu); COL.objects.link(co)
    dg=bpy.context.evaluated_depsgraph_get(); me=bpy.data.meshes.new_from_object(co.evaluated_get(dg))
    bpy.data.objects.remove(co); bpy.data.curves.remove(cu)
    o=bpy.data.objects.new(name,me); COL.objects.link(o); o.parent=ROOT; me.materials.clear(); me.materials.append(material)
    for f in me.polygons: f.use_smooth=True
    if flat!=1.0: o.scale.z=flat
    return o
dense=resample(route,0.2)
for side in (1,-1):
    sweep('Grok_Boardwalk_Curb_%s'%('L' if side>0 else 'R'),dense,side*(hw+0.04),-0.01,Pp['curb_radius'],W_POST)
# posts: few chunky rounded posts at bends, alternating sides
post_ids=list(range(3,len(samples)-3,Pp['post_every']))
for k,i in enumerate(post_ids):
    p=samples[i]; t,n=frame(i,samples); side=1 if k%2==0 else -1
    q=p+n*side*(hw+0.12)
    bm=bmesh.new(); bmesh.ops.create_cone(bm,cap_ends=True,segments=14,radius1=Pp['post_radius'],radius2=Pp['post_radius']*0.92,depth=0.5)
    for v in bm.verts: v.co+=Vector((q.x,q.y,p.z+0.05))
    o=obj_from_bm('Grok_Boardwalk_Post_%02d'%k,bm,W_POST)
    bv=o.modifiers.new('Grok_Round','BEVEL'); bv.width=0.05; bv.segments=3
    bm=bmesh.new(); bmesh.ops.create_uvsphere(bm,u_segments=14,v_segments=7,radius=Pp['post_radius']*0.95)
    for v in bm.verts: v.co.z*=0.35; v.co+=Vector((q.x,q.y,p.z+0.31))
    obj_from_bm('Grok_Boardwalk_Post_Cap_%02d'%k,bm,W_END)

# ---------- MINE: main focal destination ----------
end=route[-1]; t_end=(route[-1]-route[-6]); t_end.z=0; t_end.normalize(); n_end=Vector((-t_end.y,t_end.x,0))
mine=empty('Grok_Mine_Root',(0,0,0))
def blob(name,center,size,material,parent=mine,seg=2,squash=None,rot=0.0):
    bm=bmesh.new(); bmesh.ops.create_icosphere(bm,subdivisions=seg,radius=1.0)
    for v in bm.verts:
        d=noise.noise(v.co*1.3+center)*0.08
        v.co*=(1+d)
        v.co=Vector((v.co.x*size[0],v.co.y*size[1],v.co.z*size[2]))
        v.co=Matrix.Rotation(rot,3,'Z')@v.co+center
    o=obj_from_bm(name,bm,material,parent); subsurf(o,1); return o
base=end+t_end*0.55
W=0.86  # half inner width of portal
# big rounded stone masses framing the opening (few, large)
stones=[(-1.45,0.15,0.55,(0.62,0.6,0.62)),(1.45,0.1,0.5,(0.6,0.58,0.58)),(-1.3,0.25,1.45,(0.55,0.5,0.5)),
        (1.3,0.2,1.4,(0.55,0.5,0.52)),(-0.55,0.35,2.15,(0.62,0.52,0.42)),(0.6,0.3,2.12,(0.6,0.5,0.42)),
        (-2.05,0.75,0.45,(0.55,0.62,0.5)),(2.0,0.7,0.42,(0.5,0.6,0.48)),(0.0,0.9,2.45,(0.95,0.7,0.5))]
for k,(u,v,z,s) in enumerate(stones):
    c=base+n_end*(-u*1.12)+t_end*v; c.z=end.z+z*1.1-0.2
    blob('Grok_Mine_Stone_%02d'%k,c,tuple(x*1.18 for x in s),STONE if k<7 or k==8 else STONE_D,rot=random.uniform(0,3))
# rear hill mass so the mine reads as one big silhouette
hc=base+t_end*1.45; hc.z=end.z+0.5
blob('Grok_Mine_Hill_Mass',hc,(2.2,1.3,1.55),MOSS,seg=3)
mc=base+t_end*1.2; mc.z=end.z+1.75
blob('Grok_Mine_Moss_Crown',mc,(1.9,1.1,0.62),MOSS,seg=3)
for k,(u,z) in enumerate(((-1.25,1.85),(1.35,1.78))):
    c=base+n_end*(-u)+t_end*0.25; c.z=end.z+z
    blob('Grok_Mine_Moss_Cap_%d'%k,c,(0.42,0.36,0.17),MOSS)
# dark interior: deep recessed volume behind the portal
bm=bmesh.new(); bmesh.ops.create_cube(bm,size=1.0)
for v in bm.verts:
    v.co=Vector((v.co.x*W*2.0,v.co.y*2.2,v.co.z*1.7))
    v.co=Matrix.Rotation(math.atan2(t_end.y,t_end.x)-math.pi/2,3,'Z')@v.co+base+t_end*1.15+Vector((0,0,end.z-0.2+0.85-base.z))
tun=obj_from_bm('Grok_Mine_Dark_Interior',bm,TUNNEL,mine,smooth=False)
# wooden portal (beveled timbers)
def timber(name,center,dims,material=W_DARK,rot=0.0,tilt=0.0):
    bm=bmesh.new(); bmesh.ops.create_cube(bm,size=1.0)
    ang=math.atan2(t_end.y,t_end.x)-math.pi/2
    for v in bm.verts:
        v.co=Vector((v.co.x*dims[0],v.co.y*dims[1],v.co.z*dims[2]))
        v.co=Matrix.Rotation(tilt,3,'Y')@v.co
        v.co=Matrix.Rotation(ang,3,'Z')@v.co+center
    o=obj_from_bm(name,bm,material,mine,smooth=False)
    bv=o.modifiers.new('Grok_Round','BEVEL'); bv.width=0.045; bv.segments=3; bv.limit_method='NONE'
    return o
zb=end.z-0.05
for s in (-1,1):
    timber('Grok_Portal_Post_%s'%('L' if s<0 else 'R'),base+n_end*(s*(W+0.11))+Vector((0,0,zb+0.8-base.z)),(0.26,0.26,1.65))
    timber('Grok_Portal_Knee_%s'%('L' if s<0 else 'R'),base+n_end*(s*(W-0.12))-t_end*0.02+Vector((0,0,zb+1.42-base.z)),(0.13,0.14,0.5),W_POST,tilt=s*0.75)
timber('Grok_Portal_Header',base+Vector((0,0,zb+1.72-base.z))-t_end*0.03,(2*W+0.75,0.3,0.3))
timber('Grok_Portal_Sign_Board',base+Vector((0,0,zb+2.02-base.z))-t_end*0.08,(0.7,0.08,0.28),W_DECK)
timber('Grok_Portal_Threshold',base-t_end*0.05+Vector((0,0,end.z-0.06-base.z)),(2*W+0.2,0.36,0.1),W_POST)
for s in (-1,1):
    for e in (0,1):
        c=base+n_end*(s*(W+0.11))+Vector((0,0,zb+1.72-base.z))-t_end*0.19
        c=c+n_end*s*0.0
# lantern on left post (Godot lantern OmniLight3D follows Lantern_Pivot)
lp=base+n_end*((W+0.11))-t_end*0.3+Vector((0,0,zb+1.35-base.z))
piv=empty('Lantern_Pivot',lp,mine)
bm=bmesh.new(); bmesh.ops.create_cone(bm,cap_ends=True,segments=10,radius1=0.11,radius2=0.11,depth=0.22)
for v in bm.verts: v.co+=lp
obj_from_bm('Grok_Lantern_Glow',bm,LAMP,mine)
for dz,r in ((0.15,0.14),(-0.14,0.12)):
    bm=bmesh.new(); bmesh.ops.create_cone(bm,cap_ends=True,segments=10,radius1=r,radius2=r*0.6 if dz>0 else r,depth=0.07)
    for v in bm.verts: v.co+=lp+Vector((0,0,dz))
    obj_from_bm('Grok_Lantern_Cap_%s'%('Top' if dz>0 else 'Base'),bm,IRON,mine)

# ---------- TREES: 2-4 dominant crown masses, asymmetric, light/shadow ----------
TREES=[('Northwest',(-2.05,8.05),1.15,0.3),('West',(-2.85,1.9),1.0,2.1),('Southwest',(-3.0,-3.55),0.82,4.0),
       ('East',(3.0,0.45),0.86,1.0),('Southeast',(2.85,-5.95),1.05,5.2)]
def tree(name,xy,scale,rot):
    scale*=P['tree']['crown_scale']
    root=empty('Grok_Tree_'+name,(xy[0],xy[1],0.62))
    h=0.95*scale
    # trunk: tapered with root flare
    bm=bmesh.new()
    prof=[(0.0,0.34),(0.12,0.24),(0.35,0.17),(0.75,0.15),(1.0,0.13),(1.12,0.11)]
    rings_=[]
    for z,r in prof:
        rr=[]
        for i in range(12):
            a=2*math.pi*i/12; fl=1+(0.35*max(0,0.25-z)*4)*(0.5+0.5*math.sin(5*a+rot))
            rr.append(bm.verts.new((math.cos(a)*r*fl*scale,math.sin(a)*r*fl*scale,z*h)))
        rings_.append(rr)
    for r1,r2 in zip(rings_,rings_[1:]):
        for i in range(12): bm.faces.new((r1[i],r1[(i+1)%12],r2[(i+1)%12],r2[i]))
    bm.faces.new(rings_[-1])
    o=obj_from_bm('Grok_Tree_%s_Trunk'%name,bm,BARK,root); subsurf(o,1)
    # two short limbs into crown
    for k,(ax,ay) in enumerate(((0.55,0.15),(-0.45,-0.25))):
        bm=bmesh.new(); bmesh.ops.create_cone(bm,cap_ends=True,segments=8,radius1=0.09*scale,radius2=0.05*scale,depth=0.6*scale)
        M=Matrix.Translation((ax*0.3*scale,ay*0.3*scale,h*0.92))@Matrix.Rotation(0.75*(1 if k==0 else -1),4,'Y')@Matrix.Rotation(rot,4,'Z')
        for v in bm.verts: v.co=M@v.co
        obj_from_bm('Grok_Tree_%s_Limb_%d'%(name,k),bm,BARK,root)
    # crown: metaball of 3 dominant masses + 1-2 secondary accents, then one mesh
    mb=bpy.data.metaballs.new('Grok_Crown_MB'); mb.resolution=0.09; mb.threshold=0.6
    cz=h+0.75*scale
    masses=[((0.0,0.0,0.0),1.0),((0.62,-0.12,-0.12),0.8),((-0.55,0.18,-0.18),0.74),((0.15,0.25,0.42),0.62),((-0.25,-0.35,-0.35),0.42)]
    for (x,y,z),r in masses:
        e=mb.elements.new(); R=Matrix.Rotation(rot,3,'Z')
        e.co=R@Vector((x*1.35*scale,y*1.2*scale,cz+z*0.8*scale)); e.radius=r*scale*1.05
    mo=bpy.data.objects.new('mb_tmp',mb); COL.objects.link(mo)
    dg=bpy.context.evaluated_depsgraph_get(); me=bpy.data.meshes.new_from_object(mo.evaluated_get(dg))
    bpy.data.objects.remove(mo); bpy.data.metaballs.remove(mb)
    # gentle squash so crowns read as broad canopy, wider than tall
    for v in me.vertices: v.co.z=cz+(v.co.z-cz)*0.74
    cr=bpy.data.objects.new('Grok_Tree_%s_Crown_Mass'%name,me); COL.objects.link(cr); cr.parent=root
    me.materials.append(LEAF); 
    for f in me.polygons: f.use_smooth=True
    sm=cr.modifiers.new('Grok_Smooth','SMOOTH'); sm.factor=0.8; sm.iterations=6
    # sunlit highlight lobe (secondary accent) on the light side only
    bm=bmesh.new(); bmesh.ops.create_uvsphere(bm,u_segments=20,v_segments=12,radius=0.42*scale)
    hl=Matrix.Rotation(rot,3,'Z')@Vector((-0.35*scale,-0.55*scale,cz+0.55*scale))
    for v in bm.verts: v.co.z*=0.55; v.co+=hl
    bm.free()
    # two small daisies on the crown, no more
    for k in range(0):
        a=rot+1.2+k*1.9; d=Vector((math.cos(a)*0.95*scale,math.sin(a)*0.95*scale-0.25*scale,cz+0.2*scale))
        flower('Grok_Tree_%s_Daisy_%d'%(name,k),d,0.07*scale,WHITE,root)
    return root
def flower(name,c,r,petal,parent):
    bm=bmesh.new()
    for i in range(5):
        a=2*math.pi*i/5; t=bmesh.ops.create_uvsphere(bm,u_segments=8,v_segments=5,radius=r)
        for v in t['verts']: v.co=Vector((v.co.x*1.0,v.co.y*0.6,v.co.z*0.35)); v.co=Matrix.Rotation(a,3,'Z')@(v.co+Vector((r*0.9,0,0)))+c
    o=obj_from_bm(name,bm,petal,parent)
    bm=bmesh.new(); bmesh.ops.create_uvsphere(bm,u_segments=8,v_segments=5,radius=r*0.55)
    for v in bm.verts: v.co.z*=0.6; v.co+=c+Vector((0,0,r*0.15))
    obj_from_bm(name+'_Centre',bm,YEL,parent)
for t in TREES: tree(*t)

# ---------- GRASS: grouped natural tufts, big calm areas left empty ----------
def tuft(bm, c, size, rng):
    nb=rng.randint(*P['grass']['blades'])
    for i in range(nb):
        a=2*math.pi*i/nb+rng.uniform(-0.3,0.3); L=size*rng.uniform(0.75,1.15); w=size*0.16
        lean=rng.uniform(0.35,0.6); dirv=Vector((math.cos(a),math.sin(a),0))
        side=Vector((-dirv.y,dirv.x,0))
        pts=[]
        for k in range(4):
            f=k/3; pos=c+dirv*(L*lean*f*f+size*0.05)+Vector((0,0,L*f*(1-0.25*f)))
            wk=w*(1-f)*1.0+0.004
            pts.append((bm.verts.new(pos-side*wk),bm.verts.new(pos+side*wk)))
        for (a1,b1),(a2,b2) in zip(pts,pts[1:]): bm.faces.new((a1,b1,b2,a2))
GROUPS=[((-2.7,-8.6),6,0.45),((3.0,-7.4),5,0.5),((2.6,-4.6),5,0.45),((-2.4,-2.6),5,0.45),((-3.4,4.2),6,0.5),
        ((3.4,3.3),6,0.55),((2.6,-1.4),4,0.42),((-1.0,9.3),5,0.45),((3.0,7.8),6,0.5),((0.4,-9.6),5,0.45),
        ((-3.4,-0.4),4,0.4),((-0.9,-5.3),4,0.4)]
rng=random.Random(P['seed']+7); gi=0
for (gx,gy),count,spread in GROUPS:
    count+=2
    bm=bmesh.new(); bmd=bmesh.new(); placed=0; tries=0
    while placed<count and tries<80:
        tries+=1
        c=Vector((gx+rng.gauss(0,spread*0.6),gy+rng.gauss(0,spread*0.5),I['top_z']+0.02))
        r=(abs(c.x/I['a'])**I['n']+abs(c.y/I['b'])**I['n'])**(1/I['n'])
        if r>0.93 or path_dist(c)<P['grass']['min_path_clear']: continue
        if (c.xy-Vector((-2.1,-6.9))).length<1.0: continue
        tuft(bm if placed%3 else bmd, c, rng.uniform(0.42,0.6), rng); placed+=1
    obj_from_bm('Grok_Grass_Group_%02d'%gi,bm,G_TUFT); obj_from_bm('Grok_Grass_Group_%02d_Deep'%gi,bmd,G_TUFT_D); gi+=1

# ---------- DECORATION: few grouped stones + small flower groups ----------
STONE_GROUPS=[((-2.2,-0.6),[(0,0,0.26),(0.32,0.12,0.17),(-0.18,0.28,0.12)]),
              ((2.35,-3.2),[(0,0,0.22),(0.27,-0.1,0.14)]),
              ((-3.1,5.9),[(0,0,0.28),(0.3,0.2,0.16),(-0.1,-0.3,0.12)]),
              ((3.3,5.6),[(0,0,0.2),(-0.25,0.1,0.13)])]
for gi,((x,y),sts) in enumerate(STONE_GROUPS):
    for k,(dx,dy,r) in enumerate(sts):
        c=Vector((x+dx,y+dy,I['top_z']+r*0.35))
        blob('Grok_Stone_Group_%d_%d'%(gi,k),c,(r*1.15,r,r*0.75),STONE,parent=ROOT)
        if k==0: blob('Grok_Stone_Group_%d_Moss'%gi,c+Vector((0,0,r*0.55)),(r*0.8,r*0.7,r*0.22),MOSS,parent=ROOT)
FLOWERS=[((-2.9,-7.9),PINK,4),((3.25,-7.0),WHITE,3),((-3.35,4.6),PINK,3),((3.1,3.6),WHITE,4),((2.7,8.0),PINK,3),((-1.9,-1.9),WHITE,3)]
for gi,((x,y),pm,cnt) in enumerate(FLOWERS):
    for k in range(cnt):
        a=k*2.3+gi; c=Vector((x+math.cos(a)*0.22*(k>0),y+math.sin(a)*0.18*(k>0),I['top_z']+0.13))
        flower('Grok_Flower_Group_%d_%d'%(gi,k),c,rng.uniform(0.06,0.085),pm,ROOT)

sc=bpy.context.scene; sc.render.resolution_x=432; sc.render.resolution_y=960; sc.render.resolution_percentage=100
ROOT['grok_params_json']=json.dumps(PARAMS)
ROOT['grok_note']='Grok task-003 environment challenger; gnome not included (loaded separately, unchanged).'
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format='GLB', export_extras=True, export_apply=True,
                          export_cameras=True, export_lights=False, export_yup=True)
print('GROK_BUILD_DONE', len(bpy.data.objects))
