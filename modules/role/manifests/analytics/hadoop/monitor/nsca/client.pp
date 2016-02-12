# == Class role::analytics::hadoop::monitor::nsca::client
# This class exists in order to override the group ownership
# and permissions of the /etc/send_nsca.cfg file.  Hadoop
# processes need to be able to read this file in order to
# run send_nsca as part of Oozie submitted monitoring jobs.
class role::analytics::hadoop::monitor::nsca::client inherits icinga::nsca::client {
    File ['/etc/send_nsca.cfg'] {
        group => 'hadoop',
        mode  => '0440',
    }
}
