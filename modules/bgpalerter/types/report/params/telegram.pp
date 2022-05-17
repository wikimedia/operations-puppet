# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Telegram = Struct[{
    showPaths         => Integer[0],
    botUrl            => Stdlib::HTTPSUrl,
    chatIds           => Hash[String[1], Array[String[1]]],
    'chatIds.default' => Optional[String[1]],
}]
