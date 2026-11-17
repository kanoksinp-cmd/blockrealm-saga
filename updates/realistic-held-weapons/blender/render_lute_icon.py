import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import blender_icons as BI, hero_models as HM
BI.SRC = "/home/claude/wpn/src_icons"
BI.OUT = "/home/claude/wpn/icon_fix"
os.makedirs(BI.OUT, exist_ok=True)
orig = HM.kind_of
HM.kind_of = lambda i: None if i.endswith("_lute") else orig(i)
print("rendered", BI.render("silverstring_lute"))
