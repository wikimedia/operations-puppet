# SPDX-License-Identifier: Apache-2.0
type Logstash::SemVer = Pattern[
    /^(\d+)\.(\d+)\.(\d+)(?:[-+][0-9A-Za-z.-]+)?$/
]
