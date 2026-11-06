"""Mechanical data only. Visual references/assets are explicitly pending."""
from pathlib import Path
import json
specs={
'garlic':('Alho',[6,7,8,10,12,15,16,20],[1.2,1.2,1.05,1.05,.9,.9,.75,.75],[28,38,38,43,43,49,49,55],[1]*8,[0]*8,[0]*8),
'whip':('Chicote',[18,18,22,26,30,35,40,46],[1.3]*8,[70,70,70,80,80,92,92,92],[1,2,2,2,2,2,2,2],[0]*8,[0]*8),
'fire_wand':('Varinha de Fogo',[28,32,36,40,44,48,53,59],[2.8]*8,[300]*8,[3]*8,[160,160,180,180,205,205,230,230],[0]*8),
'runetracer':('Runa Traçante',[10,12,12,15,15,18,18,22],[2.4]*8,[300]*8,[1,1,1,2,2,2,3,3],[155,155,180,180,200,200,220,220],[2.5,3,3,3,3.5,3.5,4,4.5]),
'magic_wand':('Varinha Mágica',[11,11,11,11,16,16,16,22],[1,1,.85,.85,.85,.85,.85,.85],[260]*8,[1,2,2,3,3,4,4,4],[280]*8,[0]*8)}
for id,(name,damage,cooldown,reach,count,speed,duration) in specs.items():
 p=Path('data/weapons')/(id+'.tres')
 if p.exists():continue
 arrays={'damage':damage,'cooldown':cooldown,'reach':reach,'count':count,'projectile_speed':speed,'duration':duration,'projectile_radius':[4]*8,'pierce':[1,1,1,1,1,1,2,2] if id=='magic_wand' else [1]*8}
 text='[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/data/weapon_data.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'+f'id = "{id}"\ndisplay_name = "{name}"\nicon = ""\nmax_level = 8\n'
 for field,values in arrays.items():text+=field+' = '+('PackedInt32Array' if field in ['count','pierce'] else 'PackedFloat32Array')+'('+','.join(map(str,values))+')\n'
 p.write_text(text,encoding='utf8')
