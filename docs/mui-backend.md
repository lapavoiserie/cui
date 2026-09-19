# Being a `mui` backend

[`mui`](https://lapavoiserie.github.io/mui/) lets one source build for every
backend in this family. `cui` is the one that draws through a terminal.

## The conformance lives here

Under `cui/mui/` — one file per entry in
[`mui.Contract`](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx).
A `typedef` where the signature already matches, a small subclass where it does
not:

```haxe
package cui.mui;

typedef View = cui.View;
```

`mui` holds **no branch for `cui`**, and none for any other backend. It states
the vocabulary as data, and one line in the build file resolves it:

```
-D mui_backend=cui
--macro mui.macros.Bind.all()
```

`Bind` defines `mui.ui.Button` as an alias of `cui.mui.Button`, then checks
every constructor against the contract — arity, optionality, argument types — and
names what does not match, at the top of the build rather than at first use.

It used to be the other way round: `mui` held 132 conditional branches and had to
know all six backends. Adding a seventh meant editing twenty-two files in a
repository that had nothing to learn from it.

## What else is ours

`cui/mui/init.hxml` is the build file `mui init` writes into a new project. It
lives here because what a build for this backend needs — which libraries, which
generator macro, which output — is ours to state, and `mui` had no way of keeping
six of them honest.

`cui.mui.App` carries `@:muiOwnsMain`, which says the engine owns the process:
`run()` blocks and nothing may follow it. `Bind` turns that into the
`mui_owns_main` flag, so an application writes its `main()` once instead of
guarding it with a list of backend names.

`cui` draws a real `Image`, with whatever the terminal turns out to have.
`cui.term.Graphics` asks it — the kitty graphics protocol, Sixel (which is what
Windows Terminal has), or half blocks, which are text and work in anything with
colour, a multiplexer included. The PNG is decoded here (`cui.render.Png`),
because a terminal backend is the one that needs the pixels rather than a handle
to hand a platform. A source this cannot read, or a terminal with no colour at
all, still shows the `alt` in brackets, the way a text browser shows a picture it
cannot fetch. `width` and `height` are points, as everywhere else, and become
cells with the size a cell actually has — asked of the terminal, `ESC [ 14 t`
over `ESC [ 18 t`.

`Icon` is a character per name (`cui.nui.Icons`, a table an application may
override for its own screen), and most of them are coloured pictures: Benjamin
chose colour over compactness, the plain symbols not being visible enough. The
table records how much room each one takes, **measured in a terminal** rather
than derived from a Unicode property, because two different things happen — a
terminal advances two cells for an emoji, and the cell after it is one nobody may
write; or it advances one and *paints* over the next, which is what Windows
Terminal does with `⚙`, `⚠`, `✉` and `☎`, and which asks for a blank cell after
it instead. `move` and `grid` stay plain characters: nothing coloured reads as
what they mean. `Button` takes an icon name too.

`ScrollView` and `TabView` take a **trailing optional** argument the contract
does not name, so an application can own the scroll offset and the tab
selection. A terminal keeps neither for you. Code written against the contract
still compiles; passing one is what you do when something else drives it.

## Surfaces: Commands

Of mui's surface roles, cui hosts exactly one beyond Primary: **Commands**. An
application's `@:surface(Commands)` declaration becomes key bindings in the
event dispatch, checked before the default `q`/`Ctrl+C` handlers:

```haxe
@:surface(Commands)
function shortcuts():Array<Command> {
    return [
        new Command("New todo", focusNew).key("ctrl+n"),
        new Command("Clear done", clearDone).key("k"),
    ];
}
```

Chords are `ctrl+`/`alt+`/`shift+` plus a character, or `enter`/`escape`/`tab`.
Letters match case-insensitively; `shift` is honoured only when the chord names
it, because a terminal usually encodes shift in the character itself. A chord
cui does not understand is skipped with a logged word, once — the command stays
declared, unbound. The command thunks are sampled fresh on each key event, so
they are always current with `@:state`.

**Bindings only, for now.** There is no overlay or status bar to *display* the
declared commands, so a `Command` without a shortcut is declared but
unreachable on this backend — the discoverability half of the role waits for
an overlay. cui states what it hosts as `@:hostedRoles(Commands, Companion)` on
`cui.mui.App`, and mui refuses every other role at compile time: declaring a
`Glance` in a build targeting cui stops that build, naming both. A terminal
has no cover, and an application that learns this from an empty screen
learned it too late. An application built for several backends accepts the
gap in its own source — `@:surface(Glance, optional)` — which keeps the
declaration portable without keeping it quiet.

Checked by `tests/mui-commands.sh`, which drives `handleEvent` with
synthesized keys under the interpreter.

## The vocabulary, and the markup it makes possible

`cui` declares what its controls are, on the controls:

```haxe
@:node("Toggle")
class Checkbox extends View {
	@:prop var label:String;
	@:prop("isOn", "onToggle") var binding:CheckboxBinding;
}
```

`nui.macros.Declarations` reads that at compile time — shared by every backend,
so `cui` says only where its controls live and what a view is here
(`cui.nui.Vocabulary.DIALECT`). Everything else comes out of it:
`cui.nui.Describe` and `cui.nui.NodeRenderer` are both **generated** from those
declarations by `cui.nui.Derive`, and `mui`'s markup is checked against them:

```
--macro cui.nui.Vocabulary.registerWithMui()
```

```haxe
ui(<VStack spacing={1}>
	<Text text="Régie"/>
	<Toggle label="Muet" isOn={muet} onToggle={v -> moteur.muet(v)}/>
</VStack>);
```

A misspelt attribute names itself and lists what is accepted; a tag nothing
declares is refused. `tests/markup/check.sh` checks both.

### Why it is worth the trouble

The two directions were twenty-four cases facing twenty-two, written by hand,
for the same controls. They had already drifted in two ways:

- **`cui.ui.Password` crossed as a `TextInput`**, with the password in `text`.
  It extends `cui.ui.Input`, and the describer chose its branch with
  `Std.isOfType` in written order — so a receiver with no way to know drew it in
  clear. A flag fails open; a type fails closed, and the type is now what the
  declaration says rather than what the branch order does.
- **`Divider`, `ProgressView`, `ScrollView` and `ZStack`** were emitted by the
  describer and had no case in the renderer at all: a tree `cui` described,
  `cui` could not draw back.

Describing dispatches by class now, walking up to the nearest declared ancestor,
so nothing is ordered. `cui.mui.SafeArea` still lands on `VStack` — on `cui` it
IS a padded stack — reached without an ordered list.

`Tabs`, `ListView` and `cui.mui.ZStack` stay hand-written and say why where they
are: the first two flatten, and the third extends `VStack`, so it is asked
before the declarations.

## Colour, and the sixteen

A `nui.Color` arrives as a word — `role:danger` or `#c8323c` — and `cui`
resolves it the way a terminal can.

**A role becomes one of the sixteen**, and the sixteen are the ones the person
chose: the reds and blues of their own theme. A `danger` comes out in *their*
red, which is better than exact rather than worse — `#DC2626` picked on somebody
else's machine is a number that ignores everything this terminal knows.

The role is kept as a word (`cui.render.Color.Role`) until `Style` emits the
escape, so **a relayed tree keeps its roles**. A terminal that resolved one on
the way through would send a number onward with nothing left to say it had ever
been a role.

**Components are exact** where the terminal allows it: `Rgb` emits a truecolor
escape. **Opacity is dropped** — a cell is opaque, there is nothing behind it to
blend with, and a half-transparent red drawn solid is the closest honest answer.

Leaving here, one of the sixteen becomes conventional components, because the
wire has no way to say "the red this person chose". That is the one
approximation in the pair, and it is in the direction where nothing better
exists.

### What this corrected

`cui` described a colour as `Std.string` of its enum value — literally
`Named(Red)` on the wire — and the receiving side parsed only bare names like
`red`. So a colour did not survive a round trip **at all**: it came back as
nothing. Nobody had looked at a coloured tree crossing.

Named colours are no longer accepted either. They do not cross — `nui.Color`
says why — and taking them invited a sender to rely on something no canon
promised.

## See also

- [Adding a backend](https://lapavoiserie.github.io/mui/#/adding-a-backend) — the
  whole contract, and the two rules the six backends made necessary.
- [Backend support](https://lapavoiserie.github.io/mui/#/backend-support) — the
  generated table of what every backend answers for every type. It is generated
  by reading these very files.
