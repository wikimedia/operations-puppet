# a placeholder profile for a manual gitlab setup by
# https://phabricator.wikimedia.org/T274458
class profile::gitlab {

    ferm::service { 'gitlab-http-caches':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
