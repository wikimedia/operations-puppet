# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web(
    $workers_per_core = 4,
) {
    require ores::base

    $processes = $::processorcount * $workers_per_core
    service::uwsgi { 'ores':
        port   => 8080,
        config => {
            'wsgi-file' => "${ores::base::config_path}/ores_wsgi.py",
            chdir       => $ores::base::config_path,
            plugins     => 'python3',
            venv        => $ores::base::venv_path,
            logformat   => '[pid: %(pid)] %(addr) (%(user)) {%(vars) vars in %(pktsize) bytes} [%(ctime)] %(method) %(uri) => generated %(rsize) bytes in %(msecs) msecs (%(proto) %(status)) %(headers) headers in %(hsize) bytes (%(switches) switches on core %(core)) user agent "%(uagent)"',
            processes   => $processes,
        }
    }
}
