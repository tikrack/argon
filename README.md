# Argon

Argon is a small, dependency-free command line argument parser for the
[Salam programming language](https://www.salamlang.ir). It turns a flat list
of arguments into typed values, validates them, and generates help and shell
completion text.

Argon is written in Salam and uses only the standard library.

## Features

- Long flags (`--verbose`) and one-character short flags (`-v`).
- Options with values in all common forms: `--output file`, `--output=file`,
  `-o file`, `-ofile`, `-o=file`.
- Typed options: string, integer, float, boolean, and repeatable counters.
- Defaults, required options, allowed values, numeric ranges, and string length
  limits.
- Required, optional, and rest positional arguments with minimum and maximum
  counts.
- One level of subcommands, each with its own arguments, flags, options, help,
  and validation.
- Combined short flags (`-abc`), the `--` end-of-options marker, and negatable
  flags (`--no-color`).
- Repeatable options (`--include a --include b`) and count flags (`-vvv`).
- Automatically generated help and usage text with aligned columns, defaults,
  arguments, options, and commands.
- Optional ANSI colour that is disabled automatically when the output is not a
  terminal, when `NO_COLOR` is set, or when `ARGON_COLOR=never` is set.
- Bash and Zsh completion scripts generated from the parser definition.
- Structured parse errors instead of crashes: every failure has a stable kind,
  a readable message, the program name, and a help hint.
- Two ways to parse: `Parse(args)` for a vector you supply, or `ParseProcess()`
  for the real process arguments from `os.Args()`.

## Requirements

- Salam 0.5.4 or newer.
- A C or LLVM toolchain supported by your Salam installation (for `salam run`
  and `salam build`).

## Installing from source

Argon is a single library file, `src/argon.salam`. There is no package manager
step. Copy the file into your project, or keep the repository layout and include
it with a relative path:

```salam
include argon "src/argon.salam"
```

If Salam is not on your `PATH`, use the compiler that ships with your
installation, for example:

```sh
export PATH="$HOME/.salam/bin:$PATH"
export SALAM_STD="$HOME/.salam/bin/std"
```

`SALAM_STD` is only needed when your compiler cannot find its standard library
next to the executable.

## Quick start

```salam
// lang: en
package main

include argon "src/argon.salam"

func main:
    mut p := argon.New("my-app", "A sample Salam application")
    p.SetVersion("1.0.0")
    p.Flag("verbose", "v", "Enable verbose output")
    p.StrOption("output", "o", "Output file path", "build.txt")
    p.IntOption("count", "c", "Number of items", 1)
    p.Positional("name", "Name to greet")
    defer p.Free()

    res := p.ParseProcess()
    defer res.Free()

    if res.HelpWanted():
        print p.Help()
        ret argon.ArgExitOK
    end
    if res.VersionWanted():
        println p.VersionLine()
        ret argon.ArgExitOK
    end
    if not res.Ok():
        printerrln res.Error()
        ret res.ExitCode()
    end

    println "hello,", res.Str("name")
    println "output:", res.Str("output")
    println "count:", res.Int("count")
    println "verbose:", res.Bool("verbose")
    ret argon.ArgExitOK
end
```

Build and run it:

```sh
salam run main.salam -- --verbose --count 3 Ada
```

Output:

```text
hello, Ada
output: build.txt
count: 3
verbose: true
```

`ParseProcess()` reads `os.Args()` and skips the program path. `Parse(args)`
expects only the arguments, so tests and wrappers can pass a vector directly:

```salam
res := p.Parse(args)
```

## Defining flags and options

```salam
mut p := argon.New("tool", "Description shown in help")

p.Flag("verbose", "v", "Enable verbose output")
p.NegatableFlag("color", "", "Use colour", true)
p.CountFlag("debug", "d", "Increase the debug level")

p.StrOption("output", "o", "Output file", "out.txt")
p.IntOption("count", "c", "Number of items", 1)
p.FloatOption("ratio", "r", "Scaling ratio", 1.0)
p.BoolOption("dry", "", "Dry run", false)
p.MultiOption("include", "I", "Additional include path")
```

The parameters are `(name, short, help)`. Short names are optional and must be
exactly one character. Options that take a value also take its default:

- `StrOption(name, short, help, default)`
- `IntOption(name, short, help, default)`
- `FloatOption(name, short, help, default)`
- `BoolOption(name, short, help, default)`

`BoolOption` and `NegatableFlag` accept `--name`, `--no-name`, and
`--name=true|false`. A plain `Flag` is false unless given. A `CountFlag` counts
occurrences, so `-vvv` gives `3`.

Parser definitions return copies and do not fail at call time. If a definition
is invalid (empty name, duplicate name, duplicate short name, a command option
that clashes with a global one), the next `Parse` returns an error whose kind is
`definition`.

## Positional arguments

```salam
p.Positional("input", "Input file")
p.OptionalPositional("target", "Target name")
p.RestPositional("files", "Additional files", 0)
```

`arg_label` rules used in help:

- `Positional` is required and accepts exactly one value.
- `OptionalPositional` accepts zero or one value.
- `RestPositional` accepts all remaining values; its third parameter is the
  minimum count (`0` means zero or more).

A rest argument must be the last argument. Required arguments are checked after
options, and missing values are reported as `missing-argument`.

## Typed values and validation

Typed getters on the result:

```salam
res.Str("output")       // string
res.Int("count")        // i64
res.Float("ratio")      // f64
res.Bool("verbose")     // bool
res.Num("debug")        // occurrence count as int
res.IsSet("output")     // true only when given on the command line
```

Conversion is strict. An invalid integer, float, or boolean never becomes `0`
or `false` silently: the whole parse fails with `invalid-value` and a message
that names the option and the bad text. Integers must be decimal, with an
optional leading sign. Floats accept a decimal point and an exponent.
Booleans accept `true/false`, `1/0`, `yes/no`, and `on/off`.

Advanced rules are configured by building a spec:

```salam
mut mode := argon.NewStrOption("mode", "m", "Output mode", "fast")
mode.OneOf("fast")
mode.OneOf("slow")
mode.MinLength(2)
mode.MaxLength(8)
p.AddOption(mode)

mut level := argon.NewIntOption("level", "l", "Level", 1)
level.Range(1, 9)
p.AddOption(level)

mut tag := argon.NewStrOption("tag", "t", "Tag", "")
tag.Require()
p.AddOption(tag)

mut include := argon.NewMultiOption("include", "I", "Include path")
include.AllowRepeat()
p.AddOption(include)
```

`OneOf` appends to the allowed list. `Range` sets an inclusive numeric range.
`MinLength` and `MaxLength` count Unicode characters, not bytes. `Require` makes
an option mandatory and removes its default. `AllowRepeat` permits a value
option to appear more than once; without it, a second occurrence is
`duplicate-option`. Flags and count flags may always repeat.

Access every value of a repeatable option with `ValueCount`, `ValueAt`, or the
allocating helpers `Strs`, `Ints`, `Floats`, and `Bools`:

```salam
println res.ValueCount("include")
println res.ValueAt("include", 0)
all := res.Strs("include")
defer all.free()
```

## Subcommands

```salam
mut p := argon.New("project", "Project tool")
p.Flag("verbose", "v", "Print more details")

build := argon.NewCommand("build", "Build the project")
build.Flag("release", "r", "Build with optimizations")
build.Positional("target", "Build target")
p.AddCommand(build)

serve := argon.NewCommand("serve", "Serve the project")
mut port := argon.NewIntOption("port", "p", "Port", 8080)
port.Range(1, 65535)
serve.AddOption(port)
p.AddCommand(serve)
```

Use `res.Command()` to see which command was selected. Its options and
arguments are read through the same result object:

```salam
println res.Command()        // "build", "serve", or ""
println res.Str("target")    // command argument
println res.Int("port")      // command option
```

The first bare token is matched against command names. Root positional
arguments are only used when the token is not a command, so a program can still
define fallback arguments. Global options are accepted before and after the
command name. A command option cannot reuse a global option name; that is
reported as a `definition` error.

Commands may be hidden with `cmd.Hide()`. Hidden commands still parse, but do
not appear in help or completion.

One level of subcommands is supported. Nested subcommands are not implemented
in this version.

## Help and version

```salam
p.SetVersion("1.0.0")
print p.Help()               // root help
print p.HelpFor("build")     // command help
print p.Usage()              // just the usage block
print p.UsageFor("build")
println p.VersionLine()      // "my-app 1.0.0"
```

`--help` and `-h` are handled automatically and set `res.HelpWanted()`. The
parse still succeeds, so the caller decides where to print the text. `--version`
is recognised only after `SetVersion` is called and sets
`res.VersionWanted()`. Command help includes the command's own options and a
`Global options` section.

Help is plain text by default. Colours are optional:

```salam
p.SetColor(argon.ArgColorAuto)    // default: only on a terminal
p.SetColor(argon.ArgColorAlways)
p.SetColor(argon.ArgColorNever)
```

ANSI escapes are never emitted when `NO_COLOR` is set, when `ARGON_COLOR=never`
is set, or when colour is explicitly disabled.

## Errors

Parsing never throws or crashes on bad input. It returns a result with
`Ok() == false`, and the caller prints it:

```salam
if not res.Ok():
    printerrln res.Error()
    ret res.ExitCode()
end
```

`res.Error()` returns a multi-line message such as:

```text
error: unknown option '--colour'
try 'my-app --help' for more information.
```

The stable kinds are:

- `unknown-option`
- `unknown-command`
- `missing-value`
- `invalid-value`
- `missing-required`
- `missing-argument`
- `too-many-arguments`
- `out-of-range`
- `not-allowed`
- `too-short`
- `too-long`
- `duplicate-option`
- `unexpected-argument`
- `unexpected-value`
- `definition`

`res.ExitCode()` returns `0` for success, help, and version, and `2` for usage
errors.

## Argument syntax details

- `--name=value`, `--name value`, `-n value`, `-nvalue`, and `-n=value` all work
  for options that take a value.
- `-abc` enables flags `a`, `b`, and `c`. If one of them needs a value, the rest
  of the group becomes its value.
- A value that begins with `-` must use the `--option=value` form for string
  options. Numeric options accept negative values in the separate form, for
  example `--level -5`.
- `--` stops option processing; every later token is positional, including
  strings that begin with `-`.
- `-` on its own is a positional value.
- Non-repeatable value options may appear once. Repeating a flag is allowed;
  the last boolean value wins. Repeating a count flag increments it.

## Completion

```salam
print p.Completion("bash")
print p.Completion("zsh")
```

The returned text is a ready-to-source shell script. It completes command names
and option names (long, short, and `--no-` forms). It does not complete values;
that would require per-option value providers, which this version does not have.
An unsupported shell name returns an empty string.

## Running the examples

From the repository root:

```sh
salam run examples/basic.salam -- --formal Ada
salam run examples/options.salam -- -i input.txt -f json -w 100 --force
salam run examples/subcommands.salam -- build --release -t wasm
salam run examples/validation.salam -- -n Ada -a 30 -c green
```

Each example also supports `--help` and reports validation errors through
Argon.

## Running the tests

```sh
make test
```

or directly:

```sh
salam run tests/argon_test.salam
```

The suite contains 189 assertions covering flags, long and short forms, all
value syntaxes, defaults, typing, overflow, positionals, required items, unknown
options and commands, help text, subcommands, empty input, duplicate options,
values with spaces and empty strings, combined short flags, `--`, validation
rules, negatable flags, counters, independent parsers, extras, completion,
error formatting, definition errors, result accessors, and hidden items.

The test program returns the number of failed assertions as its exit code.

Some Salam installations do not ship a `salam test` subcommand. This project
therefore uses a normal executable test program, which works on every compiler
version.

## Project layout

```text
argon/
├── LICENSE
├── Makefile
├── README.md
├── main.salam              demo application
├── src/
│   └── argon.salam         the library
├── examples/
│   ├── basic.salam
│   ├── options.salam
│   ├── subcommands.salam
│   └── validation.salam
├── tests/
│   └── argon_test.salam
└── site/
    ├── index.html
    ├── styles.css
    ├── app.js
    └── README.md
```

There is no `argon.ini`: Argon has no runtime configuration file. Colour and
help behaviour are configured through the parser API. Creating an unused config
file would only mislead users.

## Known limitations

- Subcommands are one level deep.
- Shell completion covers names, not option values.
- Help descriptions are not word-wrapped automatically; long descriptions are
  printed on one line.
- Option and command names are compared byte for byte. ASCII names are
  recommended for portable help and completion output.
- A string option whose value starts with `-` needs the `=` form.
- The parser is not thread-safe. Create one parser per goroutine/thread.
- `salam test` is not available in every Salam release; use `make test`.
- Leaking string memory is a property of the current Salam runtime: the
  standard library exposes no string free function. All Argon vectors are freed
  by `Parser.Free()` and `Result.Free()`.

## Project status

Version 1.0.0 is usable and covered by a real test suite. The public API is
stable for the features listed above. Possible future work:

- Nested subcommands.
- Value completion providers.
- Automatic help wrapping for narrow terminals.
- Man page output.

## License

MIT. See [LICENSE](LICENSE).

Copyright (c) 2026 Argon contributors.
