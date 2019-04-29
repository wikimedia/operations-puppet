# Setting up ORES Redis database
class role::ores::redis {
    include ::profile::standard
    include ::profile::ores::redis

    system::role{ 'ores::redis':
      description => 'ORES Redis database'
    }
}
