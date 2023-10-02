# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v1.1.0](https://github.com/voxpupuli/puppet-prometheus_reporter/tree/v1.1.0) (2021-05-02)

[Full Changelog](https://github.com/voxpupuli/puppet-prometheus_reporter/compare/v1.0.0...v1.1.0)

**Breaking changes:**

- drop Ubuntu 14.04 support [\#48](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/48) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- List Puppet 7 support [\#62](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/62) ([bastelfreak](https://github.com/bastelfreak))
- Add cache\_catalog\_status and puppet\_status metrics [\#57](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/57) ([matejzero](https://github.com/matejzero))

**Closed issues:**

- Question about how to properly use this [\#56](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/56)
- config stale\_time doesn't work [\#53](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/53)
- Does this reporter support the newest node version? [\#9](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/9)

**Merged pull requests:**

- modulesync 4.1.0 / Drop Puppet 5 from metadata.json [\#63](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/63) ([bastelfreak](https://github.com/bastelfreak))
- Fix issue \#53 config stale\_time doesn't work [\#55](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/55) ([zipkid](https://github.com/zipkid))
- Feature/report puppet transaction completed [\#54](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/54) ([zipkid](https://github.com/zipkid))

## [v1.0.0](https://github.com/voxpupuli/puppet-prometheus_reporter/tree/v1.0.0) (2019-07-27)

[Full Changelog](https://github.com/voxpupuli/puppet-prometheus_reporter/compare/v0.3.1...v1.0.0)

**Breaking changes:**

- modulesync 2.7.0 and drop puppet 4 [\#39](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/39) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- Remove metric files for nodes that haven't sent reports in X time [\#44](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/44) ([LDaneliukas](https://github.com/LDaneliukas))

**Closed issues:**

- Configurable metric types  [\#42](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/42)
- Configurable environments [\#40](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/40)
- Removing deactivated node [\#38](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/38)

**Merged pull requests:**

- Allow selecting reports which are used for metrics [\#43](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/43) ([LDaneliukas](https://github.com/LDaneliukas))
- Allow configurable environments [\#41](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/41) ([LDaneliukas](https://github.com/LDaneliukas))

## [v0.3.1](https://github.com/voxpupuli/puppet-prometheus_reporter/tree/v0.3.1) (2018-10-14)

[Full Changelog](https://github.com/voxpupuli/puppet-prometheus_reporter/compare/v0.3.0...v0.3.1)

**Merged pull requests:**

- modulesync 2.2.0 and allow puppet 6.x [\#34](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/34) ([bastelfreak](https://github.com/bastelfreak))
- Remove docker nodesets [\#29](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/29) ([bastelfreak](https://github.com/bastelfreak))
- drop EOL OSs; fix puppet version range [\#27](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/27) ([bastelfreak](https://github.com/bastelfreak))

## [v0.3.0](https://github.com/voxpupuli/puppet-prometheus_reporter/tree/v0.3.0) (2018-03-31)

[Full Changelog](https://github.com/voxpupuli/puppet-prometheus_reporter/compare/v0.2.0...v0.3.0)

**Fixed bugs:**

- don't add .prom if report\_filename is set. [\#21](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/21) ([cz8s](https://github.com/cz8s))

**Merged pull requests:**

- bump puppet to latest supported version 4.10.0 [\#25](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/25) ([bastelfreak](https://github.com/bastelfreak))
- Change epochtime to seconds, add HELP/TYPE info [\#22](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/22) ([oleg-glushak](https://github.com/oleg-glushak))

## [v0.2.0](https://github.com/voxpupuli/puppet-prometheus_reporter/tree/v0.2.0) (2017-11-11)

[Full Changelog](https://github.com/voxpupuli/puppet-prometheus_reporter/compare/v0.1.0...v0.2.0)

**Merged pull requests:**

- release 0.2.0 [\#18](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/18) ([bastelfreak](https://github.com/bastelfreak))
- Update metadata.json for supported puppet versions [\#16](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/16) ([bastelfreak](https://github.com/bastelfreak))

## [v0.1.0](https://github.com/voxpupuli/puppet-prometheus_reporter/tree/v0.1.0) (2017-04-19)

[Full Changelog](https://github.com/voxpupuli/puppet-prometheus_reporter/compare/5b2be9adcf5f2fc4f467d7b5605db8e95563dc26...v0.1.0)

**Implemented enhancements:**

- remove transaction\_uuid [\#5](https://github.com/voxpupuli/puppet-prometheus_reporter/issues/5)

**Merged pull requests:**

- Release 0.1.0 [\#12](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/12) ([bastelfreak](https://github.com/bastelfreak))
- Fix syntax [\#10](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/10) ([dhoppe](https://github.com/dhoppe))
- Move to unique metrics names [\#7](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/7) ([roidelapluie](https://github.com/roidelapluie))
- Add the prometheus reporter ruby script [\#4](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/4) ([roidelapluie](https://github.com/roidelapluie))
- Add metadata.json [\#2](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/2) ([roidelapluie](https://github.com/roidelapluie))
- Add Readme and LICENSE [\#1](https://github.com/voxpupuli/puppet-prometheus_reporter/pull/1) ([roidelapluie](https://github.com/roidelapluie))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
