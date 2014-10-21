# == Manifest: ::stages
#
# Puppet segments its run into run stages. By default, there is only
# the 'main' stage. We add a 'first' stage (which runs before 'main')
# and a 'last' stage (which runs after it) as a way of ensuring that
# certain actions happen at the very beginning or very end of a run.
#

## Stages

stage { 'first': before => Stage['main'], }
stage { 'last': require => Stage['main'], }


## Run first

class { '::apt': stage => 'first', } ->
class { '::apt::update': stage => 'first', }


## Run last
