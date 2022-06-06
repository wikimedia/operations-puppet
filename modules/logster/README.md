<!-- SPDX-License-Identifier: Apache-2.0 -->
# Logster Puppet Module

[Logster](https://github.com/wikimedia/operations-debs-logster) is a utility
from Etsy for watching for changes in logfiles and reporting metrics about them.

This puppet module abstracts some details out of installing logster cronjobs.

# Usage

```puppet
# install a logster cron job to report on number
# of different error messages in apache error log.
logster::job { 'apache-error-log':
    parser  => 'ErrorLogParser',
    logfile => '/var/log/apache2/error.log',
    logster_options => '--output=ganglia',
}
```
