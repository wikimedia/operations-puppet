The `role::eventlogging::analytics::*` role classes configure various
eventlogging services for processing analytics EventLogging data.

The setup is described in detail on
<https://wikitech.wikimedia.org/wiki/EventLogging>. End-user
documentation is available in the form of a guide, located at
<https://www.mediawiki.org/wiki/Extension:EventLogging/Guide>.

mw.eventLog.logEvent() in JavaScript is used to log events.
Theses Events are URL-encoded and sent to our servers by means of an
HTTP/S request to varnish, where a varnishkafka instance forwards to Kafka.
These event streams are parsed, validated, and multiplexed into an output streams in Kafka.

`role::eventlogging::analytics::server` is a common role class that is included
by all other eventlogging analytics role classes.  It sets some commonly used
variables and also configures monitoring.

In general, the flow looks like:

```
varnishkafka -> Kafka -> eventlogging processor -> many Kafka topics

many Kafka topics -> eventlogging {files, mysql, zeromq} consumers/forwarders
```
