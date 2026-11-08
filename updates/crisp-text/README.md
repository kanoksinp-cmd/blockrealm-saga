# Crisp UI text — 9 November 2026

Regular, semibold and title Prompt faces retain the same font family and UI sizes. UI font resources use 2x glyph oversampling, grayscale antialiasing, normal hinting with autohinting, and automatic subpixel positioning. The shared HUD and label helper use linear font sampling, while explicit nearest filtering on pixel-art icon controls is retained. Label/chat shadow opacity is reduced to avoid a heavy doubled edge.

No change to the 3D framebuffer resolution, mobile pixel cap, FPS, region-memory unloading or metre-scale interiors. Font resources are built offline as binary FontFiles and referenced by replacement FontVariations, avoiding changes to imported original TTF resources. Existing animation and damage pixel fonts are retained.

Native OpenGL before/after captures at 844x390 were inspected for the mobile HUD, fashion-crafting list and Thai NPC dialogue, including diacritics, numbers and button captions. Loaded resources report the expected settings. In this sample static engine memory changed from 205 to 208 MiB and texture allocation from 50 to 53 MiB; this is not a measurement on a physical phone. All 11 main windows pass the existing desktop check at 1280x720 and mobile checks at 1055x488, 844x450 and 488x1055 (158 assertions combined). No script/assertion failures; existing shutdown resource diagnostics are separate.

Font-setting reference: [Godot Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html), [FontFile](https://docs.godotengine.org/en/stable/classes/class_fontfile.html).
