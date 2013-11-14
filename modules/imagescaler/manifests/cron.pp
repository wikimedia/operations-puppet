## need to move the /a/magick-tmp stuff to /tmp/magick-tmp this will require a
#mediawiki change, it would seem
class imagescaler::cron {
    cron { 'removetmpfiles':
        ensure  => present,
        command => "for dir in /tmp /a/magick-tmp /tmp/magick-tmp; do find \$dir
-ignore_readdir_race -type f \\( -name 'gs_*' -o -name 'magick-*' -o -name
'localcopy_*svg' -o -name 'vips-*.v' \\) -cmin +15 -exec rm -f {} \\;; done",
        user    => root,
        minute  => '*/5',
    }
}
