# Choose which init script to install, based on the init system.

Puppet::Parser::Functions.newfunction(:pick_initscript,
                                       :type => :rvalue,
                                       :arity => 5,
                                       :doc => <<-'HEREDOC'
Takes as an input the init system currently installed, the
available init scripts, and returns the chosen one.
HEREDOC
) do |vals|
  init_system, has_systemd, has_upstart, has_sysvinit, strict  = vals
  has_custom = (has_systemd || has_upstart || has_sysvinit)
  # if we don't have custom scripts, we use the system defaults
  return false unless has_custom
  case init_system
  when 'systemd'
    return 'systemd' if has_systemd
    return 'sysvinit' if has_sysvinit
    return false unless strict
    raise(ArgumentError,
          'This service unit has an upstart script but nothing useful for systemd',)
  when 'upstart'
    return 'upstart' if has_upstart
    return 'sysvinit' if has_sysvinit
    return false unless strict
    raise(ArgumentError,
          'This service unit has a systemd script but nothing useful for upstart',)
  when 'sysvinit'
    return 'sysvinit' if has_sysvinit
    return false unless strict
    raise(ArgumentError,
          'This service unit lacks a custom sysvinit script',)
  else
    raise(ArgumentError, 'Unsupported init system')
  end
end
