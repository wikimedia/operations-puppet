# Puppet StatsD reporter

This module configures a Puppet reporter that sends timing information on
Puppet runs to StatsD.

### Setup

To configure StatsD reporting, enable pluginsync and reports on your master and
clients in `puppet.conf`:

```ini
[master]
report = true
reports = statsd
pluginsync = true

[agent]
report = true
pluginsync = true
```

And include the class on all nodes you want to report:

```puppet
class { 'puppet_statsd':
  statsd_host   => 'statsd.eqiad.wmnet',
  statsd_port   => 8125,
  metric_format => 'puppet.<%= metric %>.<%= hostname %>',
}
```

### Module parameters

* `statsd_host`: StatsD host to send metrics to.
* `statsd_port`: Port on which StatsD host is listening (default: 8125).
* `metric_format`: ERB Template string for metric names; the variables
  'hostname' and 'metric' will be set in template scope to the local hostname
  and the metric name, respectively. Default: 'puppet.<%= metric %>.<%= hostname %>'.

### License

Copyright (c) 2013 Ori Livneh and Wikimedia Foundation. All Rights Reserved.

`puppet_statsd` is distributed under the GNU General Public License, Version 2,
or, at your discretion, any later version. The GNU General Public License is
available via the Web at <http://www.gnu.org/licenses/gpl-2.0.html>.
