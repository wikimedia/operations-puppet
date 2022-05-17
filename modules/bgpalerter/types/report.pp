# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report = Struct[{
    file     => Bgpalerter::Report::File,
    channels => Array[Bgpalerter::Report::Channel],
    params   => Bgpalerter::Report::Params,
}]
