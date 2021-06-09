type Apereo_cas::Urls = Struct[{
    production => Struct[{
        base_url => Stdlib::HTTPUrl,
        login_url => Stdlib::HTTPUrl,
        validate_url => Stdlib::HTTPUrl,
    }],
    staging => Struct[{
        base_url => Stdlib::HTTPUrl,
        login_url => Stdlib::HTTPUrl,
        validate_url => Stdlib::HTTPUrl,
    }],
}]
