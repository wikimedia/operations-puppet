type Apereo_cas::Urls = Struct[{
    production => Struct[{
        login_url => Stdlib::HTTPUrl,
        validate_url => Stdlib::HTTPUrl,
    }],
    staging => Struct[{
        login_url => Stdlib::HTTPUrl,
        validate_url => Stdlib::HTTPUrl,
    }],
}]
