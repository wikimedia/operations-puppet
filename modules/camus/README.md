# Camus

Puppet module to ease launching of Camus MapReduce jobs to import data
from Kafka into Hadoop.

# Usage

```puppet

# This will render a camus .properties file
# as /etc/camus.d/webrequest.properties from
# the template at camus/templates/webrequest.erb
camus::job { 'webrequest':
    kafka_brokers => ['kafka1012.eqiad.wmnet:9092, 'kafka1013.eqiad.wmnet:9092']
    # Run camus every hour
    minute => 0
}


```
