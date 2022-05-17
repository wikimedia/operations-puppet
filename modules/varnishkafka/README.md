<!-- SPDX-License-Identifier: Apache-2.0 -->
# varnishkafka puppet module

Puppet module for [varnishkafka](https://github.com/wikimedia/varnishkafka).

# Usage:

## Install/configure/run varnishkafka

```puppet
# Default varnishkafka instance with a two broker Kafka Cluster
class { 'varnishkafka':
    brokers     => ['kafka1.example.org:9092', 'kafka2.example.org:9092'],
}
```

```puppet
# varnishkafka instance using custom JSON output format
class { 'varnishkafka':
    brokers     => ['kafka1.example.org:9092', 'kafka2.example.org:9092'],
    format_type => 'json',
    format      => '%{@hostname}l %{@sequence!num}n %{%FT%T@dt}t %{Varnish:time_firstbyte@time_firstbyte!num}x %{@ip}h %{Varnish:handling@cache_status}x %{@http_status}s %{@response_size!num}b %{@http_method}m %{Host@uri_host}i %{@uri_path}U %{@uri_query}q %{Content-Type@content_type}o %{Referer@referer}i %{X-Forwarded-For@x_forwarded_for}i %{User-Agent@user_agent}i %{Accept-Language@accept_language}i'}
}
```

See the ```varnishkafka``` class docs in manifests/init.pp for more parameter documentation.

## Monitoring

```puppet
# The following classes will install logster and a custom VarnishkafkaLogster
# parser to send JSON stats from the log.statistics.file
# to Ganglia or Statsd.
class { 'varnishkafka::monitoring::ganglia': }
class { 'varnishkafka::monitoring::statsd': }
```

## Testing

Run `tox` which setup appropriate virtualenvs and run commands for you.

Python scripts should match the flake8 conventions, you can run them using:

    tox -e flake8
