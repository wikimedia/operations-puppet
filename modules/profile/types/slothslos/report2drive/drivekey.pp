# SPDX-License-Identifier: Apache-2.0
type Profile::Slothslos::Report2drive::DriveKey = Struct[{
    type                        => String,
    project_id                  => String,
    private_key_id              => String,
    private_key                 => String,
    client_email                => Pattern[/\A[^@\s]+@[^@\s]+\z/],
    client_id                   => String,
    auth_uri                    => Stdlib::HTTPUrl,
    token_uri                   => Stdlib::HTTPUrl,
    auth_provider_x509_cert_url => Stdlib::HTTPUrl,
    client_x509_cert_url        => Stdlib::HTTPUrl,
    universe_domain             => String,
}]
