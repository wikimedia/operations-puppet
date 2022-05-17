# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::File = Struct[{
    persistAlertData   => Optional[Boolean],
    alertDataDirectory => Optional[String[1]],
}]
