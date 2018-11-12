support API:
 - [ ] text subpixel
       (might require to ship freetype binaries)
 - [X] font fallback
 - [X] windows font support (GDI, freetype and harfbuzz)
 - [X] windows font support (GDI, directwrite and uniscribe)
 - [X] UI events (and plug window to ui)
 - [X] animations
 - [X] port of msdfgen
 - [-] scalable text (using msdfgen)
 - [ ] bidi
 - [ ] text effects (outline, paint etc.)
 - [ ] typecons
 - [X] resources

style support:
 - [X] css cascade
 - [X] background
 - [X] linear-gradient
 - [-] image url (net or resource)
 - [ ] font-face
 - [ ] box
 - [ ] var()
 - [ ] paint()

render API:
 - [X] rounded rect
 - [ ] circle/ellipse
 - [ ] z-position (z-buffer or sorting?)
 - [ ] vg painting (start with cairo)
 - [ ] vg buffer
 - [ ] ~~shader paint assembly~~

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
 - [ ] form
 - [ ] grid

platform support:
 - [X] win32 platform support
 - [X] xcb/xlib platform support
 - [ ] wayland platform support (with decorations)
 - [ ] xdg themes?
 - [ ] mac platform support
 - [ ] android platform support
 - [ ] ios platform support
