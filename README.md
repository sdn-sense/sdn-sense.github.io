# SDN-Sense website

SENSE documentation: [https://sdn-sense.dev](https://sdn-sense.dev/).

This repository contains the public SDN-Sense and SiteRM website. Jekyll builds
the site for GitHub Pages while preserving stable documentation URLs.

## Local development

Use Ruby 3.3 or 3.4, which remains compatible with the GitHub Pages 232
dependency set. Ruby 4 is not currently supported by that stack.

```bash
./start-local-dev.sh
```

The launcher selects an installed Ruby 3 runtime and starts the live-reloading
server at <http://127.0.0.1:4000>. It uses an existing compatible Jekyll 3.10
installation when available, otherwise it installs the missing runtime gems.
It supports common Homebrew paths on Intel and Apple Silicon. To select another
compatible runtime:

```bash
SDN_SENSE_RUBY=/path/to/ruby ./start-local-dev.sh
```

Pass Jekyll server options after the command, for example
`./start-local-dev.sh --port 4100`. Run `./start-local-dev.sh --check-runtime`
to verify runtime selection without installing dependencies or starting Jekyll.

## Validation

Run the same production build and checks used by CI:

```bash
bundle exec rake site:check
```

The task builds `_site`, checks internal links and scripts with HTMLProofer, and
validates shared accessibility, metadata, route, and release-publication
contracts.

Useful narrower tasks are:

```bash
bundle exec rake site:build
bundle exec rake site:links
bundle exec rake site:structure
bundle exec rake site:seo
```

The SEO task checks canonical and crawl metadata, Open Graph and Twitter cards,
the production sitemap and robots file, and JSON-LD structured data.

GitHub Actions builds pull requests without deploying them. A successful build
on `master` deploys the exact validated `_site` artifact to GitHub Pages.
