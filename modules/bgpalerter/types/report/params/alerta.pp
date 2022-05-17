# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Alerta = Struct[{
    severity          => Hash[Bgpalerter::Report::Channel, String[1]],
    environment       => Optional[String[1]],
    key               => Optional[String[1]],
    token             => Optional[String[1]],
    resourceTemplates => Hash[Variant[Bgpalerter::Report::Channel, Enum['default']], String[1]],
    urls              => Hash[String[1], Stdlib::HTTPSUrl],
    'urls.default'    => Optional[String[1]],
}]
