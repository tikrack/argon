# Argon documentation site

This folder contains the static documentation site for Argon. The site is
written in Salam's layout language, not in hand-written HTML. That means the
source of truth is `index.salam`; `index.html`, `index.css` and `index.js` are
generated from it.

## Design

The visual direction is a 1970s field manual for a command line tool:

- warm paper and ink, with rust and olive as the only accents;
- a monospace typewriter stack, uppercase micro-labels and numbered sections;
- hard offset shadows instead of soft elevation;
- rules, stamps, tables and fold-out notes instead of cards with gradients;
- a paper scanline texture and a dark terminal specimen.

No framework, no tracking script and no external font request are used.

## Files

```text
site/
├── index.salam     layout source; edit this file
├── index.html      generated page
├── index.css       generated styles
├── index.js        generated copy-button script
├── favicon.svg     small paper-and-rust mark
└── README.md
```

The generated files are committed so the site can be served from GitHub Pages
without a build step. If you edit `index.salam`, rebuild and commit the three
generated files together.

## Build

From the repository root:

```sh
make site
```

Or directly:

```sh
cd site
salam page build index.salam
```

The compiler writes `index.html`, `index.css` and `index.js` next to the source.
`favicon.svg` is a static asset and is not generated.

## Preview

```sh
make site-preview
```

Then open <http://127.0.0.1:8000/>. Any static file server works; the page uses
relative paths only.

## Copy buttons

Six buttons carry `data-copy` attributes. The generated `index.js` attaches one
listener to each and copies the text of the referenced `pre` element. Clipboard
access requires HTTPS or localhost, which is why the preview command is
recommended over opening the file directly.

## GitHub Pages

The workflow at `.github/workflows/pages.yml` installs Salam 0.6.2 from its
official release, runs the library test suite, rebuilds this site, and deploys
the `site/` folder with the official Pages actions.

To enable it once, open the repository on GitHub and set:

```text
Settings -> Pages -> Build and deployment -> Source: GitHub Actions
```

After the first successful run the site is published at:

```text
https://<owner>.github.io/<repository>/
```

The workflow can also be started manually from the Actions tab.

## Links

- Salam language: <https://www.salamlang.ir>
- Salam repository: <https://github.com/SalamLang/Salam>
- Argon library: `src/argon.salam` in this repository
- License: MIT
