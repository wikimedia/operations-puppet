# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::File = Enum[
    'reportFile',
    'reportEmail',
    'reportSlack',
    'reportKafka',
    'reportSyslog',
    'reportAlerta',
    'reportWebex',
    'reportHTTP',
    'reportTelegram',
    'reportPullAPI'
]

