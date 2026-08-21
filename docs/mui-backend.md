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

`cui` provides no `Image`: a terminal has no pixels to put one in, and
`mui.Contract` marks that entry optional — so `mui.ui.Image` simply does not
exist on this backend, and reaching for it is a compile error at the line that
reached.

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

## See also

- [Adding a backend](https://lapavoiserie.github.io/mui/#/adding-a-backend) — the
  whole contract, and the two rules the six backends made necessary.
- [Backend support](https://lapavoiserie.github.io/mui/#/backend-support) — the
  generated table of what every backend answers for every type. It is generated
  by reading these very files.
