# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Webex = Struct[{
    hooks           => Hash[String[1], String[1]],
    'hooks.default' => Optional[String[1]],
}]
