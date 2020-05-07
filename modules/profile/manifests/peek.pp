class profile::peek(
    $to_email = lookup('profile::peek::to_email'),
    $asana_token = lookup('profile::peek::asana_token'),
    $phab_token = lookup('profile::peek::phab_token'),
    )
{
    class {'peek':
        to_email    => $to_email,
        asana_token => $asana_token,
        phab_token  => $phab_token,
    }
}
