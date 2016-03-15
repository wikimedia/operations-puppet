# == Function: ensure_mounted( string|bool $ensure )
#
# Takes a generic 'ensure' parameter value and convert it to an
# appropriate value for use with a mount declaration.
#
# If $ensure is 'true' or 'present', the return value is 'mounted'.
# Otherwise, the return value is the unmodified $ensure parameter.
#
# === Examples
#
#  # Sample class which mounts or unmounts '/var/lib/nginx'
#  # based on the class's generic $ensure parameter:
#  class nginx ( $ensure = present ) {
#    package { 'nginx-full':
#      ensure => $ensure,
#    }
#    mount { '/var/lib/nginx':
#      ensure  => ensure_mounted($ensure),
#      device  => 'tmpfs',
#      fstype  => 'tmpfs',
#      options => 'defaults,noatime,uid=0,gid=0,mode=755,size=1g',
#    }
#  }
#
module Puppet::Parser::Functions
  newfunction(:ensure_mounted, :type => :rvalue, :arity => 1) do |args|

    ensure_param = args.first
    case ensure_param
    when 'present', 'true', true then 'mounted'
    when 'absent', 'false', false then ensure_param
    else fail(ArgumentError, "ensure_directory(): invalid argument: '#{ensure_param}'.")
    end
  end
end
