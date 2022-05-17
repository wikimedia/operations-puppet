# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Email::Smtp = Struct[{
    host      => Stdlib::Host,
    port      => Stdlib::Port,
    secure    => Optional[Boolean],
    ignoreTLS => Optional[Boolean],
    auth      => Optional[Struct[{
        user => String[1],
        pass => String[1],
        type => Enum['login', 'oauth2'],
    }]],
    tls       => Optional[Hash],
}]
