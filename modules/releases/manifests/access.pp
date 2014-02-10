define releases::access ( $user=$title, $group='wikidev' ) {
    require 'releases::groups'
    require 'groups::wikidev'
    require "accounts::${user}"
    Class['groups::wikidev'] -> Class['releases::groups'] ->
        Class["accounts::${user}"]
    User<|title == $user|>       { groups +> [ $group ] }
}
