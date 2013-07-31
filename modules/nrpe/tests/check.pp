#

include nrpe::packages
include nrpe::service

nrpe::check { 'myproc':
    command => 'mycommand',
}
