# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Slack = Struct[{
    colors          => Hash[Bgpalerter::Report::Channel, Pattern[/\#[0-9a-fA-F]{6}/]],
    showPaths       => Integer[0],
    hooks           => Hash[String[1], Stdlib::HTTPSUrl],
    'hooks.default' => Optional[String[1]],
}]
