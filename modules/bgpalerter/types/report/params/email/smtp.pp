type Bgpalerter::Report::Params::Email::Smtp = Struct[{
    host      => Stdlib::Host,
    port      => Stdlib::Port,
    secure    => Boolean,
    ignoreTLS => Boolean,
    auth      => Struct[{
        user => String[1],
        pass => String[1],
        type => Enum['login', 'oauth2'],
    }],
    tls       => Hash,
}]
