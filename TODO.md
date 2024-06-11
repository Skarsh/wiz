# Bugs
- The first frame is white, figure out why and resolve.
- Cursor capture is not working correctly in all cases, most likely its buggy in a drag and drop setting.

# Features
- Own keytype in addition to scancodes, so keys are easily rebindable.
- Input freeze/blocks the main thread on X11, probably similar issues on Windows. Need own IO thread at some point probably.
    - Xcb is supposed to have larger opporunity for asyncness.
- Simple structure for keeping track of frame times and make that part a bit more ergonomic
- Add support for Tracy OpenGL profiling
- Add multiple windows to see how that works (This kinda works, still needs to be managed properly though)
- Add Software renderer backend support
- Add OpenGL backend support (Basic version done).

# Cleanups/Refactor
- Window struct fields is a mess, should be able to prune this

# Examples
- [ ] Add software renderer example
- [x] Add basic triangle OpenGL example
- [ ] Add basic triangle Vulkan example
- [ ] Add basic triangle DirectX example
