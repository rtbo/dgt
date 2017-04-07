# D GUI Toolkit

A few design choices:
 - 2D scene graph
 - Vector graphics
    - software rendered into in-memory buffers only and upload to textures
    - backed by cairo
 - Using OpenGL to composite the SG nodes together
 - Widget toolkit built on the scene graph

Runtime Dependencies
 - Cairo
 - Freetype
 - Harfbuzz
 - Fontconfig
 - libpng
 - turbojpeg
