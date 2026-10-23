"""Write ASSET_METADATA.json for the Grok environment .blend (run inside Blender)."""
import bpy, json, sys, collections
out=sys.argv[sys.argv.index('--')+1]
objs=[o for o in bpy.data.objects]
groups=collections.Counter()
for o in objs:
    n=o.name
    k=('trees' if 'Tree' in n else 'grass' if 'Grass' in n else 'boardwalk' if 'Boardwalk' in n else
       'mine' if ('Mine' in n or 'Portal' in n or 'Lantern' in n) else 'island' if ('Island' in n or 'Hillock' in n) else
       'decoration' if ('Stone_Group' in n or 'Flower' in n) else 'kept_from_current' )
    groups[k]+=1
tris=0
for o in objs:
    if o.type=='MESH':
        dg=bpy.context.evaluated_depsgraph_get(); m=o.evaluated_get(dg).to_mesh(); m.calc_loop_triangles(); tris+=len(m.loop_triangles); o.evaluated_get(dg).to_mesh_clear()
cam=bpy.data.objects['Portrait_Camera']
meta={"asset":"GROK_T003_ENVIRONMENT","units":"metres, Blender Z-up (glTF exports Y-up)","object_count":len(objs),
 "object_groups":dict(groups),"evaluated_triangles":tris,"materials":sorted(m.name for m in bpy.data.materials if m.users),
 "camera":{"name":cam.name,"type":cam.data.type,"ortho_scale":cam.data.ortho_scale,"location":list(cam.location),"rotation_euler":list(cam.rotation_euler)},
 "render_resolution":[bpy.context.scene.render.resolution_x,bpy.context.scene.render.resolution_y],
 "pivots":"Tree roots at trunk base on meadow (z=0.62); post/plank geometry in world space under island root; Lantern_Pivot empty at portal lantern; route/anchors kept from current map",
 "modifiers":"Subdivision (island, stones, trunks), Bevel (posts, portal timbers), Smooth (crowns) - kept live in .blend, applied on GLB export",
 "params_json":bpy.data.objects['GnomiT_Grok_Island_T003']['grok_params_json'],
 "gnome":"NOT in this file. Locked gnome_r3.glb is loaded separately by the unchanged Godot integration scripts."}
json.dump(meta,open(out,'w'),indent=1); print('META_OK',tris)
