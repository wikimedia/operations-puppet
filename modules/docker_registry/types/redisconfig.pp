# SPDX-License-Identifier: Apache-2.0
type Docker_registry::Redisconfig = Struct[
    addr     => String[1],
    password => String[1],
    db       => Integer[0, 16],
]
