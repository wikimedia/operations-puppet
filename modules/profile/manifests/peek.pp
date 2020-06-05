# https://wikitech.wikimedia.org/wiki/Security/Peek
class profile::peek(
    String $to_email = lookup('profile::peek::to_email'),
    String $asana_token = lookup('profile::peek::asana_token'),
    String $phab_token = lookup('profile::peek::phab_token'),
    )
{
    class {'peek':
        to_email    => $to_email,
        asana_token => $asana_token,
        phab_token  => $phab_token,
    }
}
