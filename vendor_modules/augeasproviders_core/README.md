# augeasproviders\_core: library for building alternative Augeas-based providers for Puppet


[![Build Status](https://github.com/voxpupuli/puppet-augeasproviders_core/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-augeasproviders_core/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-augeasproviders_core/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-augeasproviders_core/actions/workflows/release.yml)
[![Code Coverage](https://coveralls.io/repos/github/voxpupuli/puppet-augeasproviders_core/badge.svg?branch=master)](https://coveralls.io/github/voxpupuli/puppet-augeasproviders_core)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/augeasproviders_core.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_core)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/augeasproviders_core.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_core)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/augeasproviders_core.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_core)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/augeasproviders_core.svg)](https://forge.puppetlabs.com/puppet/augeasproviders_core)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-augeasproviders_core)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-augeasproviders_core.svg)](LICENSE)
[![Donated by Camptocamp](https://img.shields.io/badge/donated%20by-camptocamp-fb7047.svg)](#transfer-notice)

## Module description

This module provides a library for module authors to create new types and
providers around config files, using the Augeas configuration library to read
and modify them.

The advantage of using Augeas over the default Puppet `parsedfile`
implementations is that Augeas will go to great lengths to preserve file
formatting and comments, while also failing safely when needed.

If you're a user, you want to see the main augeasproviders project at
[augeasproviders.com](http://augeasproviders.com).

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://docs.puppetlabs.com/guides/augeas.html#pre-requisites).

## Development documentation

See docs/ (run `make`) or [augeasproviders.com](http://augeasproviders.com/documentation/).

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/voxpupuli/puppet-augeasproviders_core/issues).

## Transfer Notice

This plugin was originally authored by [hercules-team](http://augeasproviders.com).
The maintainer preferred that Puppet Community take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute here instead of Camptocamp.

Previously: https://github.com/hercules-team/augeasproviders_core
