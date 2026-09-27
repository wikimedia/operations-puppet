<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v4.1.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v4.1.0) - 2026-08-31

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v4.0.2...v4.1.0)

### Added

- (MODULES-11719) Add Puppet 9 support [#391](https://github.com/puppetlabs/puppetlabs-lvm/pull/391) ([imaqsood](https://github.com/imaqsood))

## [v4.0.2](https://github.com/puppetlabs/puppetlabs-lvm/tree/v4.0.2) - 2026-06-29

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v4.0.1...v4.0.2)

### Other

- (MODULES-11840) Allow puppetlabs/stdlib 10.x [#384](https://github.com/puppetlabs/puppetlabs-lvm/pull/384) ([imaqsood](https://github.com/imaqsood))

## [v4.0.1](https://github.com/puppetlabs/puppetlabs-lvm/tree/v4.0.1) - 2026-04-30

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v4.0.0...v4.0.1)

### Fixed

- (MODULES-11756) Wait for udev to settle after lvcreate [#380](https://github.com/puppetlabs/puppetlabs-lvm/pull/380) ([imaqsood](https://github.com/imaqsood))

### Other

- (MODULES-11788) Pass converted boolean parameter [#379](https://github.com/puppetlabs/puppetlabs-lvm/pull/379) ([joshcooper](https://github.com/joshcooper))

## [v4.0.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v4.0.0) - 2026-04-13

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v3.0.1...v4.0.0)

### Changed

- (CAT-2379) Puppetcore update [#371](https://github.com/puppetlabs/puppetlabs-lvm/pull/371) ([LukasAud](https://github.com/LukasAud))

### Fixed

- (MODULES-11666) validate LV present to prevent creating empty mountpaths [#377](https://github.com/puppetlabs/puppetlabs-lvm/pull/377) ([skyamgarp](https://github.com/skyamgarp))
- (CAT-2014) Address GCP disk orphaning issue [#376](https://github.com/puppetlabs/puppetlabs-lvm/pull/376) ([LukasAud](https://github.com/LukasAud))

### Other

- ci(MODULES-11557): add Twingate setup step to GitHub Actions workflow [#370](https://github.com/puppetlabs/puppetlabs-lvm/pull/370) ([imaqsood](https://github.com/imaqsood))
- MODULES-11577 chore(ruby): upgrade Ruby from 2.7 to 3.1 [#368](https://github.com/puppetlabs/puppetlabs-lvm/pull/368) ([imaqsood](https://github.com/imaqsood))
- (CAT-2296) Update github runner image to ubuntu-24.04 [#367](https://github.com/puppetlabs/puppetlabs-lvm/pull/367) ([shubhamshinde360](https://github.com/shubhamshinde360))

## [v3.0.1](https://github.com/puppetlabs/puppetlabs-lvm/tree/v3.0.1) - 2025-02-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v3.0.0...v3.0.1)

### Fixed

- (CAT-2230) Update legacy facts [#363](https://github.com/puppetlabs/puppetlabs-lvm/pull/363) ([amitkarsale](https://github.com/amitkarsale))

## [v3.0.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v3.0.0) - 2024-12-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.3.0...v3.0.0)

### Changed

- MAINT : Removing support for centos 7 & 8 [#346](https://github.com/puppetlabs/puppetlabs-lvm/pull/346) ([malikparvez](https://github.com/malikparvez))

### Added

- (CAT-2101) Add support for Debian-12 [#353](https://github.com/puppetlabs/puppetlabs-lvm/pull/353) ([skyamgarp](https://github.com/skyamgarp))

### Fixed

- (CAT-2158) Upgrade rexml to address CVE-2024-49761 [#359](https://github.com/puppetlabs/puppetlabs-lvm/pull/359) ([amitkarsale](https://github.com/amitkarsale))

## [v2.3.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.3.0) - 2024-07-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.2.0...v2.3.0)

### Added

- CAT-1912 : Adding new getters and setters for stripes & not allowing change of stripes for an existing lvm [#343](https://github.com/puppetlabs/puppetlabs-lvm/pull/343) ([malikparvez](https://github.com/malikparvez))

## [v2.2.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.2.0) - 2024-06-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.1.0...v2.2.0)

### Added

- Allow modifying the physical extent size for volume groups [#333](https://github.com/puppetlabs/puppetlabs-lvm/pull/333) ([glangloi](https://github.com/glangloi))

### Other

- Documentation cleanup [#331](https://github.com/puppetlabs/puppetlabs-lvm/pull/331) ([kenyon](https://github.com/kenyon))
- pdk update to version 3.0.1 template-ref heads/main-0-g23c6fff [#330](https://github.com/puppetlabs/puppetlabs-lvm/pull/330) ([kenyon](https://github.com/kenyon))
- Documentation fixes [#329](https://github.com/puppetlabs/puppetlabs-lvm/pull/329) ([kenyon](https://github.com/kenyon))
- README, metadata: correct name of LVM in summaries [#328](https://github.com/puppetlabs/puppetlabs-lvm/pull/328) ([kenyon](https://github.com/kenyon))

## [v2.1.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.1.0) - 2023-09-21

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.0.3...v2.1.0)

### Added

- Add yes argument when creating/extending a LV [#279](https://github.com/puppetlabs/puppetlabs-lvm/pull/279) ([bmlit](https://github.com/bmlit))

### Fixed

- fix issues on nodes without lvm [#308](https://github.com/puppetlabs/puppetlabs-lvm/pull/308) ([rtib](https://github.com/rtib))

## [v2.0.3](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.0.3) - 2023-07-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.0.2...v2.0.3)

### Fixed

- [GH-298] fix lvm_vg_* facts [#301](https://github.com/puppetlabs/puppetlabs-lvm/pull/301) ([rtib](https://github.com/rtib))

## [v2.0.2](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.0.2) - 2023-06-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.0.1...v2.0.2)

### Fixed

- (GH-295) - fix vg datatype [#296](https://github.com/puppetlabs/puppetlabs-lvm/pull/296) ([jordanbreen28](https://github.com/jordanbreen28))
- (gh-293) - fix typo with ensure [#294](https://github.com/puppetlabs/puppetlabs-lvm/pull/294) ([jordanbreen28](https://github.com/jordanbreen28))

## [v2.0.1](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.0.1) - 2023-06-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v2.0.0...v2.0.1)

### Fixed

- (gh-290) - fix broken datatype for extents [#291](https://github.com/puppetlabs/puppetlabs-lvm/pull/291) ([jordanbreen28](https://github.com/jordanbreen28))

## [v2.0.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v2.0.0) - 2023-06-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v1.4.0...v2.0.0)

### Changed

- (maint) - Add puppet 8/Drop puppet 6 [#284](https://github.com/puppetlabs/puppetlabs-lvm/pull/284) ([jordanbreen28](https://github.com/jordanbreen28))

### Added

- pdksync - (MAINT) - Allow Stdlib 9.x [#286](https://github.com/puppetlabs/puppetlabs-lvm/pull/286) ([LukasAud](https://github.com/LukasAud))
- (CONT-974) - Add puppet module support [#283](https://github.com/puppetlabs/puppetlabs-lvm/pull/283) ([jordanbreen28](https://github.com/jordanbreen28))

### Fixed

- (maint) Update Puppet VS Code Extension ID [#255](https://github.com/puppetlabs/puppetlabs-lvm/pull/255) ([jpogran](https://github.com/jpogran))
- (RE-12896) use artifactory instead of saturn/pe-releases [#245](https://github.com/puppetlabs/puppetlabs-lvm/pull/245) ([sarameisburger](https://github.com/sarameisburger))

## [v1.4.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v1.4.0) - 2020-02-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v1.3.0...v1.4.0)

### Added

- volume_group type does not handle passing of physical_volumes as a hash [#219](https://github.com/puppetlabs/puppetlabs-lvm/pull/219) ([dacron](https://github.com/dacron))

### Fixed

- Make lv that is a substring of a vg work [#244](https://github.com/puppetlabs/puppetlabs-lvm/pull/244) ([genebean](https://github.com/genebean))
- Revert "volume_group type does not handle passing of physical_volumes as a hash" [#238](https://github.com/puppetlabs/puppetlabs-lvm/pull/238) ([tphoney](https://github.com/tphoney))

## [v1.3.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v1.3.0) - 2019-05-31

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/1.2.0...v1.3.0)

### Fixed

- (MODULES-9004) Resize XFS file system by mount point, not by volume [#232](https://github.com/puppetlabs/puppetlabs-lvm/pull/232) ([foofoo-2](https://github.com/foofoo-2))

## [1.2.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/1.2.0) - 2019-01-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/1.1.0...1.2.0)

### Added

- Added test matrix for Puppet 6 [#223](https://github.com/puppetlabs/puppetlabs-lvm/pull/223) ([dylanratcliffe](https://github.com/dylanratcliffe))

### Fixed

- (maint) - Fix rubygems-update for ruby < 2.3 [#225](https://github.com/puppetlabs/puppetlabs-lvm/pull/225) ([david22swan](https://github.com/david22swan))
- (maint) Removed test code that missed review [#224](https://github.com/puppetlabs/puppetlabs-lvm/pull/224) ([dylanratcliffe](https://github.com/dylanratcliffe))
- Don't execute the lvm commands when not supported. #193 [#222](https://github.com/puppetlabs/puppetlabs-lvm/pull/222) ([jograb](https://github.com/jograb))
- Allow puppetlabs-stdlib versions >= 5.0 [#221](https://github.com/puppetlabs/puppetlabs-lvm/pull/221) ([tdevelioglu](https://github.com/tdevelioglu))

## [1.1.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/1.1.0) - 2018-11-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/1.0.1...1.1.0)

### Added

- Add facts, functions, tasks, plans [#215](https://github.com/puppetlabs/puppetlabs-lvm/pull/215) ([dylanratcliffe](https://github.com/dylanratcliffe))
- Added support for LVM Thin Volumes [#210](https://github.com/puppetlabs/puppetlabs-lvm/pull/210) ([glorpen](https://github.com/glorpen))

### Fixed

- Confine lvm providers to linux (MODULES-6449) [#205](https://github.com/puppetlabs/puppetlabs-lvm/pull/205) ([hpcprofessional](https://github.com/hpcprofessional))

## [1.0.1](https://github.com/puppetlabs/puppetlabs-lvm/tree/1.0.1) - 2018-04-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/1.0.0...1.0.1)

### Fixed

- #puppethack Fix error when creating XFS on top of another Filesystem [#200](https://github.com/puppetlabs/puppetlabs-lvm/pull/200) ([stivesso](https://github.com/stivesso))
- Don't execute the lvm commands when not supported. [#193](https://github.com/puppetlabs/puppetlabs-lvm/pull/193) ([smithj4](https://github.com/smithj4))
- Added Hash as acceptable type for physical_volumes [#189](https://github.com/puppetlabs/puppetlabs-lvm/pull/189) ([stivesso](https://github.com/stivesso))

## [1.0.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/1.0.0) - 2017-11-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.9.0...1.0.0)

### Fixed

- (MODULES-4067) Gracefully handle blkid return code 2 [#188](https://github.com/puppetlabs/puppetlabs-lvm/pull/188) ([abottchen](https://github.com/abottchen))
- puppethack - MODULES-4753 and MODULES-4964 [#187](https://github.com/puppetlabs/puppetlabs-lvm/pull/187) ([dhollinger](https://github.com/dhollinger))
- Removing the 'extent size' check in logical_volume provider [#185](https://github.com/puppetlabs/puppetlabs-lvm/pull/185) ([lukebigum](https://github.com/lukebigum))
- Setting thinpool default to false [#182](https://github.com/puppetlabs/puppetlabs-lvm/pull/182) ([missingcharacter](https://github.com/missingcharacter))
- Update fact to add 30 second timeout; add ifs to restrict lvm commands [#158](https://github.com/puppetlabs/puppetlabs-lvm/pull/158) ([esalberg](https://github.com/esalberg))
- Set default mount option for dump to 0 [#143](https://github.com/puppetlabs/puppetlabs-lvm/pull/143) ([chrw](https://github.com/chrw))

## [0.9.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.9.0) - 2017-01-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.8.0...0.9.0)

### Added

- Added the createonly option for the volumegroup and the possibility t… [#147](https://github.com/puppetlabs/puppetlabs-lvm/pull/147) ([ricciocri](https://github.com/ricciocri))

### Fixed

- [#puppethack] fix syntax error in volume.pp [#174](https://github.com/puppetlabs/puppetlabs-lvm/pull/174) ([cjswart](https://github.com/cjswart))
- Cannot add a new volume if the volume group has the same name. Fix: Better regexp for parsing the output of lvs [#173](https://github.com/puppetlabs/puppetlabs-lvm/pull/173) ([ruriky](https://github.com/ruriky))
- resolve /dev/disk/by-path/xxxx symlinks to block devices [#167](https://github.com/puppetlabs/puppetlabs-lvm/pull/167) ([timhughes](https://github.com/timhughes))

## [0.8.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.8.0) - 2016-12-01

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.7.0...0.8.0)

### Added

- Ruby231 [#166](https://github.com/puppetlabs/puppetlabs-lvm/pull/166) ([ghoneycutt](https://github.com/ghoneycutt))
- Add support for thin provisioning and setting poolmetadatasize [#154](https://github.com/puppetlabs/puppetlabs-lvm/pull/154) ([afalko](https://github.com/afalko))
- Add missing parameters to manage mirrors for lvm::logical_volume. [#148](https://github.com/puppetlabs/puppetlabs-lvm/pull/148) ([GiooDev](https://github.com/GiooDev))

### Fixed

- Fix parsing size from lvs output [#169](https://github.com/puppetlabs/puppetlabs-lvm/pull/169) ([felixb](https://github.com/felixb))
- (MODULES-3881) in which unit output is corrected and whitespace removed [#162](https://github.com/puppetlabs/puppetlabs-lvm/pull/162) ([eputnam](https://github.com/eputnam))
- changed all instances of :true/:false to true/false [#161](https://github.com/puppetlabs/puppetlabs-lvm/pull/161) ([crayfishx](https://github.com/crayfishx))
- Corrected :false to false [#160](https://github.com/puppetlabs/puppetlabs-lvm/pull/160) ([crayfishx](https://github.com/crayfishx))
- fixed charset in provider/logical_volume/lvm.rb [#155](https://github.com/puppetlabs/puppetlabs-lvm/pull/155) ([devfaz](https://github.com/devfaz))
- fixed: executed command 'swapoff' before unmount swap partion. [#152](https://github.com/puppetlabs/puppetlabs-lvm/pull/152) ([MemberIT](https://github.com/MemberIT))
- (MODULES-3230) Add flag to Logical_volume to not resize filesystem [#151](https://github.com/puppetlabs/puppetlabs-lvm/pull/151) ([ssgelm](https://github.com/ssgelm))
- (FM-4969) aix auto tests for physical/logical volume and volume_group on aix [#150](https://github.com/puppetlabs/puppetlabs-lvm/pull/150) ([phongdly](https://github.com/phongdly))

## [0.7.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.7.0) - 2016-03-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.6.0...0.7.0)

### Added

- Added support for volumes not mounted by lvm. [#127](https://github.com/puppetlabs/puppetlabs-lvm/pull/127) ([kny78](https://github.com/kny78))

### Fixed

- Fix manage_pkg scope [#139](https://github.com/puppetlabs/puppetlabs-lvm/pull/139) ([mcanevet](https://github.com/mcanevet))

## [0.6.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.6.0) - 2015-12-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.5.0...0.6.0)

### Added

- Added support to the resize of a logical volume with swap [#136](https://github.com/puppetlabs/puppetlabs-lvm/pull/136) ([ricciocri](https://github.com/ricciocri))
- Add the --type argument to lvcreate [#129](https://github.com/puppetlabs/puppetlabs-lvm/pull/129) ([ccope](https://github.com/ccope))
- add force option for physical_volume [#120](https://github.com/puppetlabs/puppetlabs-lvm/pull/120) ([timogoebel](https://github.com/timogoebel))
- add minor device no and persist options [#119](https://github.com/puppetlabs/puppetlabs-lvm/pull/119) ([robinbowes](https://github.com/robinbowes))
- Support mkfs_cmd - fixes MODULES-2215 [#117](https://github.com/puppetlabs/puppetlabs-lvm/pull/117) ([robinbowes](https://github.com/robinbowes))
- (MODULES-2103) Adds RAL For logical volume [#114](https://github.com/puppetlabs/puppetlabs-lvm/pull/114) ([petems](https://github.com/petems))
- (MODULES-2103) Adds RAL for volume group [#113](https://github.com/puppetlabs/puppetlabs-lvm/pull/113) ([petems](https://github.com/petems))
- (MODULES-2103) Adds RAL for physical_volume [#111](https://github.com/puppetlabs/puppetlabs-lvm/pull/111) ([petems](https://github.com/petems))
- Add swap support. [#109](https://github.com/puppetlabs/puppetlabs-lvm/pull/109) ([ckoenig](https://github.com/ckoenig))
- add a fact that list all pvs in a vg [#102](https://github.com/puppetlabs/puppetlabs-lvm/pull/102) ([duritong](https://github.com/duritong))

### Fixed

- Fix issue with using force method as pvcreate argument [#135](https://github.com/puppetlabs/puppetlabs-lvm/pull/135) ([walkamongus](https://github.com/walkamongus))
- If size_is_minsize is true, consider the size in sync if already larg… [#125](https://github.com/puppetlabs/puppetlabs-lvm/pull/125) ([dfairhurst](https://github.com/dfairhurst))
- (logical_volume) Fix regex on new_size and coerce to float instead of int [#123](https://github.com/puppetlabs/puppetlabs-lvm/pull/123) ([tdevelioglu](https://github.com/tdevelioglu))
- Make size_is_minsize usable from lvm::logical_volume [#121](https://github.com/puppetlabs/puppetlabs-lvm/pull/121) ([AndreasPfaffeneder](https://github.com/AndreasPfaffeneder))
- (maint) Fixes specs for Puppet ~> 2.7.0 [#112](https://github.com/puppetlabs/puppetlabs-lvm/pull/112) ([petems](https://github.com/petems))
- Fix bad regexp [#108](https://github.com/puppetlabs/puppetlabs-lvm/pull/108) ([rabbitt](https://github.com/rabbitt))
- Made logical_volume $size an optional parameter [#95](https://github.com/puppetlabs/puppetlabs-lvm/pull/95) ([campos-ddc](https://github.com/campos-ddc))

## [0.5.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.5.0) - 2015-04-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.4.0...0.5.0)

### Added

- mirrors - rc 3 [#96](https://github.com/puppetlabs/puppetlabs-lvm/pull/96) ([mwangel](https://github.com/mwangel))
- Allow different values for pass and dump [#94](https://github.com/puppetlabs/puppetlabs-lvm/pull/94) ([esalberg](https://github.com/esalberg))
- Support for readahead count when creating new volumes [#90](https://github.com/puppetlabs/puppetlabs-lvm/pull/90) ([JamieCressey](https://github.com/JamieCressey))

### Fixed

- Handle undef value in lvm::logical_volume [#105](https://github.com/puppetlabs/puppetlabs-lvm/pull/105) ([riton](https://github.com/riton))
- Ordering of resources and removal of some defaults in class lvm [#100](https://github.com/puppetlabs/puppetlabs-lvm/pull/100) ([TorLdre](https://github.com/TorLdre))
- Fix filesystem type detection [#93](https://github.com/puppetlabs/puppetlabs-lvm/pull/93) ([ckaenzig](https://github.com/ckaenzig))
- Fix unquoted strings in cases [#92](https://github.com/puppetlabs/puppetlabs-lvm/pull/92) ([raphink](https://github.com/raphink))
- escape dashes in lv name for dmsetup remove [#81](https://github.com/puppetlabs/puppetlabs-lvm/pull/81) ([jhofeditz](https://github.com/jhofeditz))

## [0.4.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.4.0) - 2014-12-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.3.3...0.4.0)

### Added

- Added Parameter 'size_is_minsize' (true|false(default))  [#72](https://github.com/puppetlabs/puppetlabs-lvm/pull/72) ([elconas](https://github.com/elconas))
- Feature/mkfs options and stripes [#66](https://github.com/puppetlabs/puppetlabs-lvm/pull/66) ([mcanevet](https://github.com/mcanevet))
- Support newer releases of Puppet [#65](https://github.com/puppetlabs/puppetlabs-lvm/pull/65) ([ghoneycutt](https://github.com/ghoneycutt))

### Fixed

- MODULES-1324 Fix metadata URL and update for 0.3.4 release [#83](https://github.com/puppetlabs/puppetlabs-lvm/pull/83) ([cyberious](https://github.com/cyberious))
- volume_group: physical_volumes is an unsorted array [#79](https://github.com/puppetlabs/puppetlabs-lvm/pull/79) ([raphink](https://github.com/raphink))

## [0.3.3](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.3.3) - 2014-09-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.3.2...0.3.3)

### Added

- MODULES-1219 Add Compatability for >= 4.1.0 stdlib [#73](https://github.com/puppetlabs/puppetlabs-lvm/pull/73) ([cyberious](https://github.com/cyberious))

### Fixed

- Make metadata match puppet module build output [#75](https://github.com/puppetlabs/puppetlabs-lvm/pull/75) ([underscorgan](https://github.com/underscorgan))
- Fix issue where setting initial_size didn't prevent --extents=100%FREE [#67](https://github.com/puppetlabs/puppetlabs-lvm/pull/67) ([underscorgan](https://github.com/underscorgan))

## [0.3.2](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.3.2) - 2014-06-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.3.1...0.3.2)

### Added

- Add autorequire for the volume_group [#61](https://github.com/puppetlabs/puppetlabs-lvm/pull/61) ([adamcrews](https://github.com/adamcrews))

### Fixed

- Fix exec that was missing a path attribute [#59](https://github.com/puppetlabs/puppetlabs-lvm/pull/59) ([adamcrews](https://github.com/adamcrews))
- Fix a size comparison [#58](https://github.com/puppetlabs/puppetlabs-lvm/pull/58) ([tih](https://github.com/tih))

## [0.3.1](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.3.1) - 2014-04-10

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.3.0...0.3.1)

## [0.3.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.3.0) - 2014-04-10

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.2.0...0.3.0)

### Added

- Add init class [#52](https://github.com/puppetlabs/puppetlabs-lvm/pull/52) ([mcanevet](https://github.com/mcanevet))

## [0.2.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.2.0) - 2014-02-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.1.2...0.2.0)

### Added

- Add AIX support for LVs and Filesystems [#43](https://github.com/puppetlabs/puppetlabs-lvm/pull/43) ([crayfishx](https://github.com/crayfishx))
- xfs online resizing support [#40](https://github.com/puppetlabs/puppetlabs-lvm/pull/40) ([sgzijl](https://github.com/sgzijl))
- use ensure_resources to handle multiple physical_volume in a volume_grou... [#38](https://github.com/puppetlabs/puppetlabs-lvm/pull/38) ([kjetilho](https://github.com/kjetilho))
- Add option for initial_size (rebased, original by @kvisle) [#35](https://github.com/puppetlabs/puppetlabs-lvm/pull/35) ([tzachz](https://github.com/tzachz))
- Add lvm_support fact [#25](https://github.com/puppetlabs/puppetlabs-lvm/pull/25) ([raphink](https://github.com/raphink))

### Fixed

- Extents doesn't work as a property, no method implemented. Also, add stripes and stripesize. [#49](https://github.com/puppetlabs/puppetlabs-lvm/pull/49) ([mcallaway](https://github.com/mcallaway))
- Fix issue 16174 (http://projects.puppetlabs.com/issues/16174) [#47](https://github.com/puppetlabs/puppetlabs-lvm/pull/47) ([mkrakowitzer](https://github.com/mkrakowitzer))
- Suppress facter warnings on systems that don't support LVM. [#44](https://github.com/puppetlabs/puppetlabs-lvm/pull/44) ([smithj4](https://github.com/smithj4))
- Make the XFS support optional, not required. [#42](https://github.com/puppetlabs/puppetlabs-lvm/pull/42) ([smithj4](https://github.com/smithj4))
- Bug/21826: resize2fs isn't called during resizing on ruby>1.8 [#33](https://github.com/puppetlabs/puppetlabs-lvm/pull/33) ([artem-sidorenko](https://github.com/artem-sidorenko))
- Allow for physical_volumes and volume_groups that change a system lives [#30](https://github.com/puppetlabs/puppetlabs-lvm/pull/30) ([csschwe](https://github.com/csschwe))
- Feature/14718: size 'undef' doesn't work when creating a new logical volume [#28](https://github.com/puppetlabs/puppetlabs-lvm/pull/28) ([raskas](https://github.com/raskas))
- Fix messages with new_size variables in logical_volume/lvm.rb [#27](https://github.com/puppetlabs/puppetlabs-lvm/pull/27) ([raphink](https://github.com/raphink))

## [0.1.2](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.1.2) - 2013-03-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/0.1.1...0.1.2)

### Added

- use 'blkid' instead of 'mount' to check the filesystem type [#23](https://github.com/puppetlabs/puppetlabs-lvm/pull/23) ([mbornoz](https://github.com/mbornoz))

### Fixed

- Fix undefined method: inject for String [#20](https://github.com/puppetlabs/puppetlabs-lvm/pull/20) ([robbat2](https://github.com/robbat2))

## [0.1.1](https://github.com/puppetlabs/puppetlabs-lvm/tree/0.1.1) - 2012-08-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/v0.1.0...0.1.1)

### Fixed

- Added missing K unit to lv validate test. [#7](https://github.com/puppetlabs/puppetlabs-lvm/pull/7) ([smithj4](https://github.com/smithj4))

## [v0.1.0](https://github.com/puppetlabs/puppetlabs-lvm/tree/v0.1.0) - 2011-09-01

[Full Changelog](https://github.com/puppetlabs/puppetlabs-lvm/compare/f316fbb5ac458214c6d3d8e1532e1cd1294cdac0...v0.1.0)
