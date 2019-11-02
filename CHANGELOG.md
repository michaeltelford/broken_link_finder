# Broken Link Finder Change Log

## v0.0.0 (TEMPLATE - DO NOT EDIT)
### Added
- ...
### Changed/Removed
- ...
### Fixed
- ...
---

## v0.9.4
### Added
- ...
### Changed/Removed
- Updated `wgit` gem to version 0.5.0 which contains improvements and bugs fixes.
### Fixed
- ...
---

## v0.9.3
### Added
- ...
### Changed/Removed
- ...
### Fixed
- A bug resulting in some servers dropping crawl requests from broken_link_finder.
---

## v0.9.2
### Added
- ...
### Changed/Removed
- Updated `wgit` gem to version 0.4.0 which brings a speed boost to crawls.
### Fixed
- ...
---

## v0.9.1
### Added
- `BrokenLinkFinder::Finder.crawl_site` alias: `crawl_r`.
### Changed/Removed
- Upgraded `wgit` to v0.2.0.
- Refactored the code base (no breaking changes).
### Fixed
- ...
---

## v0.9.0
### Added
- The `version` command to the executable.
- The `--threads` aka `-t` option to the executable's `crawl` command to control crawl speed vs. resource usage.
### Changed/Removed
- Changed the default number of maximum threads for a recursive crawl from 30 to 100. Users will see a speed boost with increased resource usage as a result. This is configurable using the new `crawl` command option e.g. `--threads 30`.
### Fixed
- Several bugs by updating the `wgit` dependancy.
- A bug in the report logic causing an incorrect link count.
---

## v0.8.1
### Added
- ...
### Changed/Removed
- ...
### Fixed
- Updated `wgit` dep containing bug fixes.
---

## v0.8.0
### Added
- Logic to prevent re-crawling links for more efficiency.
### Changed/Removed
- Updated the `wgit` gem which fixes a bug in `crawl_site` and adds support for IRI's.
### Fixed
- Bug where an error from the executable wasn't being rescued.
---

## v0.7.0
### Added
- Added the `--verbose` flag to the executable for displaying all ignored links.
- Added the `--concise` flag to the executable for displaying the broken links in summary form.
- Added the `--sort-by-link` flag to the executable for displaying the broken links found and the pages containing that link (as opposed to sorting by page by default).
### Changed/Removed
- Changed the **default** sorting (format) for ignored links to be summarised (much more concise) reducing noise in the reports.
- Updated the `README.md` to reflect the new changes.
### Fixed
- Bug where the broken/ignored links weren't being ordered consistently between runs. Now, all links are reported alphabetically. This will change existing report formats.
- Bug where an anchor of `#` was being returned as broken when it shouldn't.
---

## v0.6.0
### Added
- Support for ignored links e.g. mailto's, tel's etc. The README has been updated.
### Changed/Removed
- Only HTML files now have their links verified, JS files for example, do not have their contents checked. This also boosts crawl speed.
- Links are now reported exactly as they appear in the HTML (for easier location after reading the reports).
### Fixed
- Links with anchors aren't regarded as separate pages during a crawl anymore, thus removing duplicate reports.
---

## v0.5.0
### Added
- Anchor support is now included meaning the response HTML must include an element with an ID matching that of the anchor in the link's URL; otherwise, it's regarded as broken. Previously, there was no anchor support.
- The README now includes a How It Works section detailing what constitutes a broken link. See this for more information.
### Changed/Removed
- Any element with a href or src attribute is now regarded as a link. Before it was just `<a>` elements.
### Fixed
- ...
---
