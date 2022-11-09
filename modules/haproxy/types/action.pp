# SPDX-License-Identifier: Apache-2.0
type Haproxy::Action = Struct[{
    'context'   => Enum['tcp-request connection', 'http-request', 'http-response'],
    'verb'      => String[1],
    'condition' => Optional[String],  # e.g. "if cache_miss or cache_pass"
    'comment'   => Optional[String],
}]
