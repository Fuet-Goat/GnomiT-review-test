extends RefCounted
const TREASURES=preload("res://assets/storybook/treasures_v4.png")
const MATERIALS=preload("res://assets/storybook/ui_materials_v1.png")
const MAP=preload("res://assets/storybook/descending_world_v2.png")
const GNOMES=preload("res://assets/storybook/gnome_lantern_cutout_v3.png")
const WALK=preload("res://assets/storybook/gnome_walk_atlas_v1.png")
const SIDE_GNOMES=preload("res://assets/storybook/side_gnomes_v1.png")
const MAP_POINTS={"entry":Vector2(0.62,0.315),"hollow":Vector2(0.40,0.392),"seam":Vector2(0.62,0.463),"pearl":Vector2(0.40,0.531),"goldore":Vector2(0.62,0.602),"terraces":Vector2(0.40,0.665),"bridge":Vector2(0.62,0.731),"boss":Vector2(0.62,0.882)}
const SOIL=preload("res://assets/storybook/soil_goal.svg")
const FONT=preload("res://assets/font.ttf")
static func region(texture: Texture2D, index: int, columns: int, rows: int) -> AtlasTexture:
	var result=AtlasTexture.new();result.atlas=texture
	var extent=Vector2(texture.get_width()/float(columns),texture.get_height()/float(rows))
	result.region=Rect2(Vector2(index%columns,int(index/columns))*extent,extent)
	result.filter_clip=true
	return result
static func treasure(kind: int) -> AtlasTexture:return region(TREASURES,kind%6,3,2)
static func material(index: int) -> AtlasTexture:
	var t=region(MATERIALS,index,3,2)
	# The lower-row crown reaches into top-row padding; exclude it from ordinary badges.
	if index<3:t.region.size.y=448
	return t
static func gnome(_victory: bool=false) -> AtlasTexture:return region(GNOMES,0,1,1)
static func hero_walk_frame(index: int) -> AtlasTexture:return region(WALK,index%4,2,2)
static func side_gnome(index: int) -> AtlasTexture:return region(SIDE_GNOMES,index%2,2,1)
static func font(weight: float=800.0) -> FontVariation:
	var f=FontVariation.new();f.base_font=FONT
	f.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):weight}
	return f
static func panel(tint: Color=Color.WHITE) -> StyleBoxTexture:
	var s=StyleBoxTexture.new();s.texture=MATERIALS;s.region_rect=Rect2(560,504,448,438);s.modulate_color=tint
	s.texture_margin_left=24;s.texture_margin_right=24;s.texture_margin_top=24;s.texture_margin_bottom=24
	s.content_margin_left=24;s.content_margin_right=24;s.content_margin_top=16;s.content_margin_bottom=16
	return s

static func round_button() -> StyleBoxTexture:
	var s=StyleBoxTexture.new();s.texture=MATERIALS;s.region_rect=Rect2(1024,0,512,512);return s
