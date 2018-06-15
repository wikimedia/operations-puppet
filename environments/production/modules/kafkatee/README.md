# Kafkatee Puppet Module

Can be used to set up and run multiple kafkatee instances consuming topics from a Kafka cluster
and outputting them to multiple locations.

NOTE: This module is not usable outside of the wikimedia/operations/puppet repository.

## Usage

```puppet

    # Configure and run a kafkatee instance consuming from
    # the topics 'webrequest_misc' and 'webrequest_text'.
    kafkatee::instance { 'webrequest':
        kafka_brokers   => ['kafka1001:9092', 'kafka1002:9092'],
        output_encoding => 'json',
        output_format   => undef,
        inputs          => [
            {
                'topic'      => 'webrequest_misc',
                'partitions' => '0-11',
                'options'    => {
                    ''encoding'' => 'json',
                },
                'offset'     => 'end',
            },
            {
                'topic'      => 'webrequest_text',
                'partitions' => '0-23',
                'options'    => {
                    ''encoding'' => 'json',
                },
                'offset'     => 'end',
            }
        ]
    }

    # Set up some kafkatee outputs for this instance.
    # Output sampling 1/100 to a file:
    kafkatee::output { 'mytopic-sampled-100':
        # NOTE: instance name must match a declared kafkatee::instance.
        instance_name => 'webrequest',
        destination => '/path/to/mytopic-sampled-100.json',
        type        => 'file',
        sample      => 100,
    }

    # Output with no sampling to a piped filtering process:
    kafkatee::output { 'mytopic-filtered':
        instance_name => 'webrequest',
        destination => 'grep -v "whocares" >> /path/to/mytopic-filtered.json'
        type        => 'pipe',
    }
```

