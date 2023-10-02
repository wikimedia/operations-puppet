# Puppet Prometheus Reports Processor

This module contains a Puppet [reports processor][rpc] that writes report
metrics in a format that is accepted by [Prometheus node_exporter Textfile
Collector][pnetc].

[rpc]:https://docs.puppet.com/puppet/latest/reference/reporting_about.html
[pnetc]:https://github.com/prometheus/node_exporter#textfile-collector


## How to

### Puppet setup

Include this module in your path, and create a file named `prometheus.yaml` in
your Puppet configuration directory. Example:

```yaml
---
textfile_directory: /var/lib/prometheus-dropzone
```

Configuration options include:
- `textfile_directory` - [String] Location of the node_exporter `collector.textfile.directory` (Required)
- `report_filename` - [String] If specified, saves all reports to a single file (must end with .prom)
- `environments` - [Array] If specified, only creates metrics on reports from these environments
- `reports` - [Array] If specified, only creates metrics from reports of this type (changes, events, resources, time)
- `stale_time` - [Integer] If specified, delete metric files for nodes that haven't sent reports in X days

Include `prometheus` in your Puppet reports configuration; enable pluginsync:

```ini
[agent]
report = true
pluginsync = true

[master]
report = true
reports = prometheus
pluginsync = true
```

Note: you can use a comma separated list of reports processors:

```ini
reports = puppetdb,prometheus
```

### Prometheus

Call the Prometheus node_exporter with the `--collector.textfile.directory`
flag.

```
node_exporter --collector.textfile.directory=/var/lib/prometheus-dropzone
```

Note: The directory can be anywhere, but must be matched to the one set in `prometheus.yml` above.

### Sample

```
puppet_report_resources{name="Changed",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Failed",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Failed to restart",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Out of sync",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Restarted",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Scheduled",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Skipped",environment="production",host="node.example.com"} 0
puppet_report_resources{name="Total",environment="production",host="node.example.com"} 519
puppet_report_time{name="Acl",environment="production",host="node.example.com"} 3.8629975709999984
puppet_report_time{name="Anchor",environment="production",host="node.example.com"} 0.002442332
puppet_report_time{name="Augeas",environment="production",host="node.example.com"} 10.629003954
puppet_report_time{name="Concat file",environment="production",host="node.example.com"} 0.0026740609999999997
puppet_report_time{name="Concat fragment",environment="production",host="node.example.com"} 0.012010700000000003
puppet_report_time{name="Config retrieval",environment="production",host="node.example.com"} 20.471957786
puppet_report_time{name="Cron",environment="production",host="node.example.com"} 0.000874118
puppet_report_time{name="Exec",environment="production",host="node.example.com"} 0.4114313850000001
puppet_report_time{name="File",environment="production",host="node.example.com"} 0.32955574000000015
puppet_report_time{name="File line",environment="production",host="node.example.com"} 0.002702939
puppet_report_time{name="Filebucket",environment="production",host="node.example.com"} 0.0003994
puppet_report_time{name="Grafana datasource",environment="production",host="node.example.com"} 0.187452552
puppet_report_time{name="Group",environment="production",host="node.example.com"} 0.0031514940000000003
puppet_report_time{name="Mysql datadir",environment="production",host="node.example.com"} 0.000422795
puppet_report_time{name="Package",environment="production",host="node.example.com"} 1.670733222
puppet_report_time{name="Service",environment="production",host="node.example.com"} 0.8740041969999999
puppet_report_time{name="Total",environment="production",host="node.example.com"} 38.468031933999995
puppet_report_time{name="User",environment="production",host="node.example.com"} 0.005163427
puppet_report_time{name="Yumrepo",environment="production",host="node.example.com"} 0.0010542610000000001
puppet_report_changes{name="Total",environment="production",host="node.example.com"} 0
puppet_report_events{name="Failure",environment="production",host="node.example.com"} 0
puppet_report_events{name="Success",environment="production",host="node.example.com"} 0
puppet_report_events{name="Total",environment="production",host="node.example.com"} 0
puppet_report{environment="production",host="node.example.com"} 1477054915347
puppet_transaction_completed{environment="production",host="node.example.com"} 1
puppet_cache_catalog_status{state="not_used",environment="production",host="node.example.com"} 0
puppet_cache_catalog_status{state="explicitly_requested",environment="production",host="node.example.com"} 1
puppet_cache_catalog_status{state="on_failure",environment="production",host="node.example.com"} 0
puppet_status{state="failed",environment="production",host="node.example.com"} 0
puppet_status{state="changed",environment="production",host="node.example.com"} 0
puppet_status{state="unchanged",environment="production",host="node.example.com"} 1
```

## Contributors

[See Github](https://github.com/voxpupuli/puppet-prometheus_reporter/graphs/contributors).

Special thanks to [Puppet, Inc](http://puppet.com) for Puppet, and its store
reports processor, to [EvenUp](https://letsevenup.com/) for their
[graphite](https://github.com/evenup/evenup-graphite_reporter) reports
processor, and to [Vox Pupuli](https://voxpupuli.org) to provide a platform
that allows us to develop of this module.

## Copyright and License

Copyright © 2016 [Puppet Inc](https://www.puppet.com/)

Copyright © 2016 [EvenUp](https://letsevenup.com/)

Copyright © 2016 [Multiple contributors][mc]

[mc]:https://github.com/voxpupuli/puppet-prometheus_reporter/graphs/contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
