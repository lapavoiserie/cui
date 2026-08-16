# Architecture

## Rendering Pipeline

```
body() → View Tree → measure() → render(buffer) → diff(prev, curr) → ANSI output
                                                          ↑
                          @:state mutation → dirty flag → re-render
```

### 1. View Tree Construction

`App.body()` returns a tree of `View` objects. This is called on every state change (immediate-mode rendering).

### 2. Layout (Measure)

Each view implements `measure(constraint:Constraint):Size`:

- **Exact**: the view must be exactly this size
- **AtMost**: the view can be up to this size
- **Unbounded**: the view reports its natural size

VStack/HStack use a two-pass algorithm:
1. Measure children with `Unbounded` to get natural sizes
2. If total exceeds available space, compact children keep their size, greedy children share the remainder

### 3. Render to Buffer

Each view implements `render(buffer:Buffer, area:Rect)`:

- `Buffer` is a 2D grid of `Cell` (character + style)
- `area` is the assigned rectangle from layout
- Views write characters and styles into the buffer

### 4. Diff and Flush

`Renderer.render(prev, curr, backend)` compares the new buffer against the previous frame cell by cell. Only changed cells produce ANSI escape sequences:

```
\x1b[row;colH     (cursor movement)
\x1b[0m            (style reset)
\x1b[38;2;r;g;bm  (foreground color)
\x1b[1m            (bold)
X                  (character)
```

This minimizes terminal I/O — typically only a few bytes per frame for small UI changes.

### 5. Event Loop

```
enterRawMode() → enterAlternateScreen() → hideCursor() → enableMouse()

loop:
    pollEvent(16ms)          // ~60fps cap
    handle Ctrl+C            // built-in quit
    handle Tab/Shift-Tab     // focus navigation
    dispatch to focused view // Button, Input, ListView, etc.
    offer to the view tree   // deepest child first: ScrollView, Tabs
    dispatch to app handler  // handleEvent()
    if state dirty:
        re-render

disableMouse() → showCursor() → leaveAlternateScreen() → leaveRawMode()
```

## Terminal Backend

The `Backend` interface abstracts platform-specific terminal operations:

| Method | Purpose |
|--------|---------|
| `enterRawMode()` / `leaveRawMode()` | Disable line buffering, echo |
| `enterAlternateScreen()` / `leaveAlternateScreen()` | Separate screen buffer |
| `hideCursor()` / `showCursor()` | Cursor visibility |
| `enableMouseCapture()` / `disableMouseCapture()` | SGR mouse mode |
| `write()` / `flush()` | Terminal output |
| `getSize()` | Terminal dimensions |
| `pollEvent()` | Non-blocking input with timeout |

### Terminal — the six primitives underneath

`AnsiBackend` speaks escape sequences, and it speaks the same ones everywhere.
What differs by system is only how raw mode is entered, how the size is asked
for and how a byte is waited for. `cui.backend.native.Terminal` dispatches those
six and nothing above it knows there was a choice.

**PosixTerminal** (macOS, Linux) uses C FFI via `@:headerCode` and
`@:functionCode`:
- **Raw mode**: `tcgetattr`/`tcsetattr` with termios
- **Terminal size**: `ioctl(TIOCGWINSZ)`
- **Non-blocking input**: `select()` with timeout + `read()`

**WindowsTerminal** does the same against the console API:
- **Raw mode**: `SetConsoleMode` — `ENABLE_VIRTUAL_TERMINAL_PROCESSING` on the
  output handle so escape sequences are interpreted, and
  `ENABLE_VIRTUAL_TERMINAL_INPUT` on the input handle so keys come back *as*
  escape sequences. Both are needed and neither implies the other: enabling only
  the first gives a screen that draws correctly and never responds. Line mode,
  echo and signal processing are cleared, matching `ICANON`/`ECHO`/`ISIG`.
- **Terminal size**: `GetConsoleScreenBufferInfo`, reading `srWindow` rather
  than the buffer — a console buffer is usually far taller than the window.
- **Non-blocking input**: `WaitForSingleObject` on the input handle, then
  `ReadFile`. The handle is signalled for records that produce no bytes at all
  (resize, focus, key-up), so those are peeked and discarded first; without
  that, resizing the window freezes the application.
- **UTF-8**: `SetConsoleOutputCP(CP_UTF8)`, because output goes through
  `Sys.print` and Haxe strings arrive as UTF-8. Without it the box-drawing
  characters in a frame become mojibake.

Everything saved is restored on leaving raw mode, including the code page: a
console mode outlives the process that changed it, so a crash-free exit that
forgot to restore would leave the user's shell without echo.

#### Why the choice is made at run time

`#if windows` is the obvious answer and it is wrong twice. It does not work —
Haxe defines no such thing, verified by compiling the same file on macOS and on
Windows and printing which branch was taken: "not defined" on both. So the
Windows branch would never have compiled *on Windows*, and the failure would
have surfaced as a POSIX terminal that does not build.

It is also the wrong shape: a compile-time switch answers for the machine doing
the compiling, which stops being the right machine the moment anyone
cross-compiles.

So the branch that genuinely must be resolved before compiling — which system's
headers exist — is left to the **C preprocessor**, which does know `_WIN32`.
Each implementation guards its own native code, both compile everywhere, one of
them to empty bodies. The branch that only matters at run time is taken at run
time, by asking the system being run on.

### Input Parsing

The `AnsiBackend` parses raw bytes from stdin into `Event` values:

| Bytes | Event |
|-------|-------|
| `0x09` | Tab |
| `0x0D` | Enter |
| `0x1B` | Start of escape sequence |
| `0x1B[A` | Up arrow |
| `0x1B[B` | Down arrow |
| `0x1B[Z` | Shift-Tab (BackTab) |
| `0x1B[<btn;col;rowM` | SGR mouse press |
| `0x1B[<btn;col;rowm` | SGR mouse release |
| `0x01`-`0x1A` | Ctrl+A through Ctrl+Z |
| `>= 0x80` | UTF-8 multi-byte character |

## Focus System

`FocusManager` maintains a focus ring:

1. After each render, `buildFocusRing()` walks the view tree depth-first
2. Views with `focusable = true` are collected in order
3. Tab/Shift-Tab cycles `focusIndex`
4. Mouse clicks call `hitTest()` on the view tree to find the clicked focusable view
5. Events are dispatched to the focused view first, then offered to the rendered
   tree, then to the app handler

### Why the tree pass exists

Focus is for what you interact with **directly** — something to type into, to
activate. A `ScrollView` and a `Tabs` are neither, so neither is focusable, and
with only a focused dispatch their `handleEvent` was never called: a page taller
than the terminal could not be moved and a tabbed app was stuck on its first
tab, with nothing to press.

Making them focusable was the smaller change and the wrong one — you would tab
past every button on the page to reach the scrolling. So what focus declines is
offered to the tree, **deepest child first**, and the order matters in both
directions: focus keeps priority so a text field still owns its own arrows, and
an inner view wins over the container around it, so nested scroll views behave
the way they do everywhere else.

Nothing in the loop knows which view wants which key. A view says so by
answering `handleEvent` — the same contract the focused dispatch uses. Adding a
view that reacts to a key means touching nothing else.

One exception is worth knowing: `Tabs` renders its content from its own `tabs`
list rather than from `children`, so no walk of the tree can reach a view inside
a tab. The tabs own those views, so the tabs forward what they do not use.

## State System

The `@:state` macro (`StateMacro.build()`) is triggered by `@:autoBuild` on `App`, `ViewComponent`, and `Observable`:

1. Scans class fields for `@:state` metadata
2. Changes field type: `Int` → `IntState`, `Bool` → `BoolState`, etc.
3. Injects initialization into the constructor

At runtime, any `State.set()` call sets `StateBase.dirtyFlag = true`. The event loop checks this flag after each event and triggers a re-render if set.
