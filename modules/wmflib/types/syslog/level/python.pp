# SPDX-License-Identifier: Apache-2.0

# Capitalized names are allowed since they can be passed verbatim to
# logging.basicConfig 'level' argument by some software.
type Wmflib::Syslog::Level::Python = Enum[
  'notset',
  'NOTSET',
  'debug',
  'DEBUG',
  'info',
  'INFO',
  'warning',
  'WARNING',
  'error',
  'ERROR',
  'critical',
  'CRITICAL',
]
