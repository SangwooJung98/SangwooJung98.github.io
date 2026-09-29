# Sangwoo Jung's homepage

Jekyll site based on [al-folio](https://github.com/alshedivat/al-folio), published at <https://sangwoojung98.github.io>.
The maintained pages are the homepage, CV, publications and the 404 page.

## Local setup

Use Ruby **3.3.12** and Node **22.23.2**, as recorded in `.ruby-version` and `.node-version`.
Install ImageMagick so that `convert -version` works (macOS: `brew install imagemagick`; Ubuntu: `sudo apt-get install imagemagick`).
A Ruby version manager can install the Ruby version; macOS's system Ruby is too old.

```sh
gem install bundler -v 2.6.9
bundle config set --local path vendor/bundle
bundle install
npm ci
npm run build
npm run preview
```

Open <http://127.0.0.1:4000>. `npm run preview` serves the exact production output in `_site`.
For editing with automatic regeneration, use `bundle exec jekyll serve --host 127.0.0.1 --port 4000 --livereload`.
Run `npm run build` again before reviewing production output or deploying; it also runs PurgeCSS and final asset checks.
Restart Jekyll after changing `_config.yml` or Ruby plugins.

There is one native build path. The upstream Docker images, lockfile-deleting entrypoint and Docker publishing workflows have been removed.
Python, Jupyter, global npm packages and external blog feeds are not required.

## Updating content

| Content                                  | Source                                                         |
| ---------------------------------------- | -------------------------------------------------------------- |
| Introduction and profile options         | `_pages/about.md`                                              |
| CV sections                              | `_data/cv.yml`                                                 |
| Downloadable CV                          | `assets/pdf/my_cv.pdf`                                         |
| Publications                             | The four category files in `_bibliography/`                    |
| Homepage publication selection and order | `_data/selected_papers.yml` (BibTeX keys only)                 |
| Research PDFs                            | `pdf/` — keep existing filenames and URLs                      |
| Navigation and contact accounts          | `_config.yml`, page front matter                               |
| Colors and layout                        | `_sass/_themes.scss`, `_sass/_layout.scss`, `_sass/_base.scss` |

Keep each paper in its category file only. The homepage uses the same entry, so its title, authors, links and BibTeX stay consistent with the publications page.
Unknown or duplicate selected keys fail the build. The original Co-RaL selection's inconsistent page range and missing organization now come from its canonical conference entry.

For a paper with shared first authorship, add `cofirst={2}` to its BibTeX entry (use the number of leading co-first authors).
The homepage and publications list add `*` after those names. The copied BibTeX keeps the original author names and omits this display field.
The current annotations were verified on page 1 of the linked PDFs: GaRLILEO (Chiyun Noh, Sangwoo Jung), MOANA (Hyesu Jang, Wooseong Yang), TRansPose (Jeongyun Kim, Myung-Hwan Jeon), and Quantitative 3D Map Accuracy Evaluation (Sanghyun Hahn, Seunghun Oh).

The default theme is dark. A visitor's saved light, dark or system preference takes precedence; use the navigation theme button to change it.

`assets/img/prof_pic.jpg` remains the source image. Production builds generate three WebP sizes automatically.
Do not commit `_site`, `vendor/bundle`, `node_modules` or generated WebP files.

## Checks and intentional content changes

```sh
npm run format
npm run format:check
npm test
npm run build
```

`npm run build` starts with a clean destination. It compiles the site, removes unused CSS, versions CSS from the final bytes, then checks:

- The four expected HTML pages and the three content URLs in the sitemap.
- Main text, publication order, and matching homepage/publications BibTeX.
- Every local HTML asset/link, responsive image and CSS font reference.
- Canonical URLs, CSS versions, and the bytes of all research/CV PDFs.

`test/fixtures/published.json` records the expected content. During this refactor it was captured from the deployed site at the commits named inside it.
When deliberately changing your biography, publications, CV or PDF files, the first build will report the corresponding snapshot difference.
Review the generated pages and PDF changes, then run:

```sh
npm run baseline:update
npm run check
npm run format
```

Commit the reviewed fixture changes together with the content. Do not refresh the fixture to silence unexpected differences.
`baseline:update` only updates the content/PDF snapshot; it does not bypass route, asset, canonical or sitemap checks.

## Deployment and review

Pull requests and every push to `master` run the same locked build and checks. Bibliography, PDF, Sass and plugin changes all trigger CI.
The build job has read-only repository permissions. After it passes, the deploy job downloads that exact artifact and publishes it to `gh-pages`.
Pull requests never deploy. A manual run on another branch only validates and creates an artifact.

The three main pages keep their layout, colors, navigation, light/dark/system themes, publication buttons and CV download.
The demo URLs listed in [docs/retired-urls.json](docs/retired-urls.json) intentionally become 404s. Existing research PDFs are preserved byte for byte.
The 404 page offers a home link instead of redirecting every removed demo to the homepage.

For a visual review, check `/`, `/cv/` and `/publications/` at desktop and mobile widths in both light and dark mode;
also open the mobile menu, follow a CV/publications sidebar link, expand a Bib panel and copy its contents.
External websites can reject automated requests; the build checks local destinations and does not use third-party availability as a deployment gate.

## Attribution

The original [MIT license](LICENSE) is retained. See [third-party credits](docs/THIRD_PARTY.md) for the retained libraries and icon fonts.
