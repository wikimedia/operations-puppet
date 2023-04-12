# nagios

#### Table of Contents

1. [Description](#description)
2. [Limitations - OS compatibility, etc.](#limitations)
3. [Development - Guide for contributing to the module](#development)

<a id="description"></a>
## Description

The nagios module is used to manage Nagios's various configuration files.

<a id="limitations"></a>
## Limitations

All `nagios_*` types default to having a `target` under `/etc/nagios/`, but should work on any system as long as an appropriate `target` is set for that system.

<a id="development"></a>
## Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)
