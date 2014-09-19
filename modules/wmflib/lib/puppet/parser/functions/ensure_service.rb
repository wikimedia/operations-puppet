# == Function: ensure_service( string|bool $ensure )
#
# Takes a generic 'ensure' parameter value and convert it to an
# appropriate value for use with a service declaration.
#
# If $ensure is 'true' or 'present', the return value is 'running'.
# Otherwise, the return value is 'stopped'.
#
# === Examples
#
#  # Sample class which starts or stops the redis service
#  # based on the class's generic $ensure parameter:
#  class redis( $ensure = present ) {
#    package { 'redis-server':
#      ensure => $ensure,
#    }
#    service { 'redis':
#      ensure  => ensure_service($ensure),
#      require => Package['redis-server'],
#    }
#  }
#
module Puppet::Parser::Functions
  newfunction(:ensure_service, :type => :rvalue, :arity => 1) do |args|
    ensure_param = args.first
    case ensure_param
    when 'running', 'present', 'true', true then 'running'
    when 'stopped', 'absent', 'false', false then 'stopped'
    else fail(ArgumentError, "ensure_service(): invalid argument: '#{ensure_param}'.")
    end
  end
end
