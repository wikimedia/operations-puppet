# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Http = Struct[{
    hooks          => Hash[String[1], String[1]],
    hooks_default  => String[1],
    templates      => Hash[Variant[Bgpalerter::Report::Channel, Enum['default']], String[1]],
    isTemplateJSON => Boolean,
    headers        => Hash[String[1], String[1]],
    showPaths      => Integer[0],
}]
