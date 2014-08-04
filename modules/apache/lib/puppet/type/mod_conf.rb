Puppet::Type.newtype(:mod_conf) do
  @doc = <<-END
    Manages symlinks in /etc/apache2/mods-enabled.

    *NOTE*: This custom type is considered private to the Apache
    module. You should never declare instances of this type!

    The behavior of Debian's a2enmod / a2dismod / a2query utilities
    is a bit loose when it comes to module .conf files: if a module
    is disabled, enabling it will enable both .load and .conf files,
    but if only the .load file is enabled, running a2enmod won't do
    anything, and a2query will report that the module is enabled.

    If a module has a .conf file as well as a .load file, this module
    ensures that symlinks to both files are managed in tandem.

    Examples:

     # Ensures both /etc/apache2/mods-available/status{.conf,.load}
     # are symlinked from /etc/apache2/mods-enabled:

     mod_conf { 'mpm_prefork':
       ensure => present,
     }

  END

  ensurable

  newparam(:name) do
    desc 'The name of the module.'
  end

  autorequire(:package) do
    ['apache2']
  end

  autorequire(:file) do
    # This simply ensures that *if* file resources matching these names
    # exist, they are handled before the mod_conf resource.
    ["/etc/apache2/mods-available/#{@parameters[:name]}.load",
     "/etc/apache2/mods-available/#{@parameters[:name]}.conf"]
  end
end
