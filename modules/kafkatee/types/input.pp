# SPDX-License-Identifier: Apache-2.0
type Kafkatee::Input = Struct[{
    topic      => String[1],
    partitions => Pattern[/\d+(-\d+)?/],
    options    => Hash[String[1], String[1]],
    offset     => String[1],
}]