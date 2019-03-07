class html5depurate::monitoring(
    $port = 4339
)
{
    monitoring::service { 'html5depurate':
        description   => 'Html5Depurate',
        check_command => "check_http_on_port!${port}",
        notes_url     => 'https://www.mediawiki.org/wiki/Html5Depurate',
    }
}
