support API:
 - [ ] text subpixel (might require to ship freetype binaries)
 - [X] font fallback
 - [X] windows font support (GDI, freetype and harfbuzz)
 - [ ] windows font support (GDI, directwrite and uniscribe)
 - [X] UI events (and plug window to ui)
 - [X] animations
 - [X] port of msdfgen
 - [ ] scalable text (using msdfgen)
 - [ ] bidi algorithm
 - [ ] text effects (outline, paint etc.)
 - [ ] typecons
 - [X] resources

style support:
 - [X] css cascade
 - [X] background
 - [X] linear-gradient
 - [X] image url (resource)
 - [ ] image url (download)
 - [ ] font-face
 - [ ] box?
 - [ ] var()
 - [ ] paint()

render API/impl:
 - [X] rounded rect
 - [ ] circle/ellipse
 - [ ] z-position (z-buffer or sorting?)
 - [ ] vg painting (start with cairo into image/texture)
 - [ ] vg path (resume the Path class in deprecated branch)
 - [ ] vg buffering (send vg commands to the render thread to execute cairo there)
 - [ ] ~~shader paint assembly~~
 - [ ] releasing resources
 - [ ] custom geometry rendering?

views:
 - [X] image view
 - [X] label
 - [X] button
 - [X] check-box
 - [ ] radio
 - [ ] background
 - [ ] frame
 - [ ] table
 - [ ] tree

layouts:
 - [X] linear
 - [X] margins
 - [ ] form
 - [ ] grid

platform support:
 - [X] win32 platform support
 - [X] xcb/xlib platform support
 - [ ] client side decorations
 - [ ] wayland platform support (with decorations)
 - [ ] xdg themes?
 - [ ] mac platform support
 - [ ] android platform support
 - [ ] ios platform support
