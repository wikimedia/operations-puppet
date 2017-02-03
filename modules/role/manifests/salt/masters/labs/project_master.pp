# A salt master manages minions within a project
#
# filtertags: labs-project-servermon labs-project-debdeploy labs-project-integration labs-project-ttmserver
class role::salt::masters::labs::project_master {

    $salt_state_roots    = { 'base' => ['/srv/salt'] }
    $salt_file_roots     = { 'base' => ['/srv/salt'] }
    $salt_pillar_roots   = { 'base' => ['/srv/pillars'] }
    $salt_module_roots   = { 'base' => ['/srv/salt/_modules'] }
    $salt_returner_roots = { 'base' => ['/srv/salt/_returners'] }

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
                # For simplicity of test/dev we trust all of labs
                # to run deploy module calls, but rely on security groups
                # to secure this.
        salt_peer_run       => {
            '.*.eqiad.wmflabs' => ['deploy.*'],
        },
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '10',
        salt_state_roots    => $salt_state_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
        salt_auto_accept    => true,
    }

}
