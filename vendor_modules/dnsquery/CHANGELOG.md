# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v5.0.1](https://github.com/voxpupuli/puppet-dnsquery/tree/v5.0.1) (2023-05-10)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/v5.0.0...v5.0.1)

**Fixed bugs:**

- 138: Allow nil value for config\_info [\#141](https://github.com/voxpupuli/puppet-dnsquery/pull/141) ([b4ldr](https://github.com/b4ldr))

## [v5.0.0](https://github.com/voxpupuli/puppet-dnsquery/tree/v5.0.0) (2023-04-24)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/v4.0.0...v5.0.0)

**Breaking changes:**

- Drop Puppet 6 support [\#136](https://github.com/voxpupuli/puppet-dnsquery/pull/136) ([bastelfreak](https://github.com/bastelfreak))
- drop deprecated functions [\#133](https://github.com/voxpupuli/puppet-dnsquery/pull/133) ([b4ldr](https://github.com/b4ldr))
- TXT: join text records [\#127](https://github.com/voxpupuli/puppet-dnsquery/pull/127) ([b4ldr](https://github.com/b4ldr))

**Implemented enhancements:**

- config\_info: Allow users to override the resolver config [\#129](https://github.com/voxpupuli/puppet-dnsquery/pull/129) ([b4ldr](https://github.com/b4ldr))

**Fixed bugs:**

- fix deprecation warnings [\#132](https://github.com/voxpupuli/puppet-dnsquery/pull/132) ([nferch](https://github.com/nferch))
- dnsquery::lookup: update lookup so it always resolves AAAA records [\#131](https://github.com/voxpupuli/puppet-dnsquery/pull/131) ([b4ldr](https://github.com/b4ldr))

**Closed issues:**

- dnsquery::lookup dosen't return AAAA if the local machine has no ipv6 [\#130](https://github.com/voxpupuli/puppet-dnsquery/issues/130)

## [v4.0.0](https://github.com/voxpupuli/puppet-dnsquery/tree/v4.0.0) (2023-02-18)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/3.0.0...v4.0.0)

**Breaking changes:**

- move functions under the dnsquery namespace [\#114](https://github.com/voxpupuli/puppet-dnsquery/pull/114) ([b4ldr](https://github.com/b4ldr))

**Implemented enhancements:**

-  Add DNS-SOA record. [\#123](https://github.com/voxpupuli/puppet-dnsquery/pull/123) ([Heidistein](https://github.com/Heidistein))

**Closed issues:**

- Vox Pupuli migration [\#115](https://github.com/voxpupuli/puppet-dnsquery/issues/115)
- dns\_aaaa should return lowercase characters instead [\#113](https://github.com/voxpupuli/puppet-dnsquery/issues/113)
- Installs 53M vendor directory from puppetforge  [\#84](https://github.com/voxpupuli/puppet-dnsquery/issues/84)
- dns\_cname: stops puppet with an error if record is not resolvable [\#57](https://github.com/voxpupuli/puppet-dnsquery/issues/57)
- dns\_ptr is broken on Ubuntu 18.04 [\#41](https://github.com/voxpupuli/puppet-dnsquery/issues/41)
- tarball for v3.0.0 on the Forge includes vendored Ruby [\#13](https://github.com/voxpupuli/puppet-dnsquery/issues/13)
- Anyone know how to use this in a template? [\#12](https://github.com/voxpupuli/puppet-dnsquery/issues/12)
- Non-fatal versions of lookups [\#8](https://github.com/voxpupuli/puppet-dnsquery/issues/8)

**Merged pull requests:**

- Documentation: update the docs strings [\#126](https://github.com/voxpupuli/puppet-dnsquery/pull/126) ([b4ldr](https://github.com/b4ldr))
- Fix typos in deprecation warnings [\#125](https://github.com/voxpupuli/puppet-dnsquery/pull/125) ([alexjfisher](https://github.com/alexjfisher))
- documentation: update readme, references and prepare for release [\#124](https://github.com/voxpupuli/puppet-dnsquery/pull/124) ([b4ldr](https://github.com/b4ldr))
- rubocop: fix rubocop violations [\#122](https://github.com/voxpupuli/puppet-dnsquery/pull/122) ([b4ldr](https://github.com/b4ldr))
- spec: Fix spec tests [\#121](https://github.com/voxpupuli/puppet-dnsquery/pull/121) ([b4ldr](https://github.com/b4ldr))
- aaaa: Ensure AAAA answers are lowercase [\#120](https://github.com/voxpupuli/puppet-dnsquery/pull/120) ([b4ldr](https://github.com/b4ldr))
- rubocop: fix violations [\#119](https://github.com/voxpupuli/puppet-dnsquery/pull/119) ([b4ldr](https://github.com/b4ldr))
- cleanup: update metadata.json license [\#118](https://github.com/voxpupuli/puppet-dnsquery/pull/118) ([b4ldr](https://github.com/b4ldr))
- Add dns\_rlookup function. [\#101](https://github.com/voxpupuli/puppet-dnsquery/pull/101) ([olifre](https://github.com/olifre))

## [3.0.0](https://github.com/voxpupuli/puppet-dnsquery/tree/3.0.0) (2017-03-24)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/2.0.1...3.0.0)

## [2.0.1](https://github.com/voxpupuli/puppet-dnsquery/tree/2.0.1) (2015-10-23)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/2.0.0...2.0.1)

**Closed issues:**

- release fixed array version [\#7](https://github.com/voxpupuli/puppet-dnsquery/issues/7)

**Merged pull requests:**

- correctly convert array of Resolv::IPv4 or Resolv::IPv6 to array strings [\#6](https://github.com/voxpupuli/puppet-dnsquery/pull/6) ([timogoebel](https://github.com/timogoebel))

## [2.0.0](https://github.com/voxpupuli/puppet-dnsquery/tree/2.0.0) (2014-10-23)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/1.0.0...2.0.0)

**Closed issues:**

- UTF-8 character in module metadata leads to failed catalog compilation [\#4](https://github.com/voxpupuli/puppet-dnsquery/issues/4)

## [1.0.0](https://github.com/voxpupuli/puppet-dnsquery/tree/1.0.0) (2014-10-14)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/0.1.1...1.0.0)

**Closed issues:**

- Tag this version [\#3](https://github.com/voxpupuli/puppet-dnsquery/issues/3)

**Merged pull requests:**

- changed é to e to workaround a puppet utf bug [\#5](https://github.com/voxpupuli/puppet-dnsquery/pull/5) ([nustiueudinastea](https://github.com/nustiueudinastea))

## [0.1.1](https://github.com/voxpupuli/puppet-dnsquery/tree/0.1.1) (2014-06-19)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/0.1.0...0.1.1)

**Merged pull requests:**

- In 1.8.7 getresource.map is invalid [\#2](https://github.com/voxpupuli/puppet-dnsquery/pull/2) ([jhuntwork](https://github.com/jhuntwork))

## [0.1.0](https://github.com/voxpupuli/puppet-dnsquery/tree/0.1.0) (2013-08-30)

[Full Changelog](https://github.com/voxpupuli/puppet-dnsquery/compare/011cd21670f2a8a0acb8858c651b12a5bd321f54...0.1.0)

**Merged pull requests:**

- dns\_lookup.rb: support arrays of names [\#1](https://github.com/voxpupuli/puppet-dnsquery/pull/1) ([pcarrier](https://github.com/pcarrier))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
