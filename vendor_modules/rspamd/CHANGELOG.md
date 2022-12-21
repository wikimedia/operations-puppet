# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.1] - 2023-01-13
### Added
- Drop the inherit keyword and assert private resources as private
- Bump version requirements for stdlib & concat

## [1.3.0] - 2021-02-03
### Added
- Increase compatible dependency versions in metadata ([#8])
- Add parameter `$package_ensure` ([#10])
- Convert to PDK

## [1.2.0] - 2020-04-07
This release solely changes documentation and metadata.

### Changed
- Increase compatible dependency versions in metadata ([#7])
- Extend README examples ([#5])

## Release [1.1.0] - 2019-03-03
This version adds a convenience parameter for simplified hiera usage.

### Added
- $rspamd::config parameter to simplify usage from hiera out of the box ([#2]).

## Release [1.0.2] - 2018-01-28
This version fixes a regression introduced in 1.0.0 that caused a non-working
APT repo to be added on Debian/Ubuntu by default.

### Fixes
- Fix links in this changelog
- Fix repo being added with `undef` URL by default on Debian/Ubuntu.

## Release [1.0.1] - 2018-01-28
This version contains some minor documentation fixes only

### Fixes
- Fix links in this changelog

## Release [1.0.0] - 2018-01-28
First stable release. This version now requires Puppet 4.9 or greater.

### Added
- FreeBSD support (no repo management)

### Changed
- Large refactoring to adhere to standard module layout
- `$packages_install` has been renamed to `$package_manage`
- Minimum required Puppet version is now 4.9
- Several style/lint related changes

## Release [0.2.1] - 2017-07-31
First public release. This version is used by the author on a production system.

### Fixes
- Fixes several style/lint related issues

## Release [0.2.0] - 2017-07-31
This version removes `rmilter` support in favor of the `rspamd_proxy` [milter support](https://rspamd.com/doc/workers/rspamd_proxy.html) added in Rspamd 1.6

## Version 0.1.0 (unreleased)
Initial development, was not used or tested on a production system

[Unreleased]: https://gitlab.wikimedia.org/repos/sre/puppet-rspamd/compare/v1.3.1...master
[1.3.1]: https://gitlab.wikimedia.org/repos/sre/puppet-rspamd/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/oxc/puppet-rspamd/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/oxc/puppet-rspamd/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/oxc/puppet-rspamd/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/oxc/puppet-rspamd/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/oxc/puppet-rspamd/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/oxc/puppet-rspamd/compare/v0.2.1...v1.0.0
[0.2.1]: https://github.com/oxc/puppet-rspamd/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/oxc/puppet-rspamd/compare/1980687...v0.2.0
[#10]: https://github.com/oxc/puppet-rspamd/pull/10
[#8]: https://github.com/oxc/puppet-rspamd/pull/8
[#7]: https://github.com/oxc/puppet-rspamd/pull/7
[#5]: https://github.com/oxc/puppet-rspamd/issues/5
[#2]: https://github.com/oxc/puppet-rspamd/pull/2
