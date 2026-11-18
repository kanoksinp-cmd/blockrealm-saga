# Natural wing pose

The wyvern wings lay flat against the back in one straight line. A small
SkeletonModifier3D (`scripts/voxel/wing_pose.gd`) now runs after the wing
animation. It swings both wing roots back about 28° into a V, lifts them about
10°, and adds a slow breathing sway. The wings also sit a little further from
the back (`Avatar.attach_wings`). Preview: `previews/before-after.png` (top row
before, bottom row after; a top-down view is in the corner).
