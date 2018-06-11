# xhgui is a graphical interface for XHProf data
# built on MongoDB and used by the performance team
class profile::webperf::xhgui {

    ferm::service { 'webperf-xhgui-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$INTERNAL',
    }

    ferm::service { 'webperf-xhgui-mongo':
        proto  => 'tcp',
        port   => '27017',
        srange => '$INTERNAL',
    }

    class { '::mongodb': }
}
