define mediawiki::errorpage(
    $filepath,
    $title = 'Wikimedia Error',
    $content = '',
    $footer = undef,
) {
    $errorpage  = {
        title   => $title,
        content => $content,
        footer  => $footer,
    }
    file { $filepath:
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => template('mediawiki/errorpage.html.erb'),
    }
}
