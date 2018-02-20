## Usage

```puppet

    # Install kafkatee and point it at a Kafka Cluster.
    class { 'kafkatee':
        kafka_brokers => ['kafka1.example.org:9092', 'kafka2.example.org:9092'],
    }

    # Consume from the JSON formatted input topic 'mytopic'.
    kafkatee::input { 'mytopic':
        topic       => 'mytopic',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'stored',
    }

    # Output sampling 1/100 to a file:
    kafkatee::output { 'mytopic-sampled-100':
        destination => '/path/to/mytopic-sampled-100.json',
        type        => 'file',
        sample      => 100,
    }

    # Output with no sampling to a piped filtering process:
    kafkatee::output { 'mytopic-filtered':
        destination => 'grep -v "whocares" >> /path/to/mytopic-filtered.json'
        type        => 'pipe',
    }
```

## Testing

Run `tox` which setup appropriate virtualenvs and run commands for you.

Python scripts should match the flake8 conventions, you can run them using:

    tox -e flake8
