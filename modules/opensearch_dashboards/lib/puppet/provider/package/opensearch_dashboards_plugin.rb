# SPDX-License-Identifier: Apache-2.0
require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:opensearch_dashboards_plugin, parent: Puppet::Provider::Package) do
  desc 'Package management via `opensearch-dashboards-plugin`.'

  commands osd_plugin: '/usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin'

  has_feature :installable, :uninstallable, :versionable, :upgradeable

  def self.instances
    # list all plugin packages that dashboards knows about and return an array of Type instances
    packages = []
    cmd = "#{command(:osd_plugin)} --allow-root list"
    execute(cmd).each_line do |line|
      line = line.chomp
      parsed = %r{^'?(\S+)@(\S+)$}.match(line)
      next if parsed.nil?
      plugin_name, version = parsed.captures
      packages << new(
        name: plugin_name,
        ensure: version,
        provider: name,
      )
    end
    packages
  end

  def query
    # get an instance of a specific plugin package
    pkg = self.class.instances.find do |package|
      @resource[:name] == package.name
    end
    pkg ? pkg.properties : nil
  end

  def install
    # install a plugin package from either a repo or a specific file
    # rubocop:disable GuardClause
    raise ArgumentError, _('Source parameter required.') if @resource[:source].nil?
    is_zip = @resource[:source].slice(-4..-1) == '.zip'

    if [:present, :latest].include? @resource[:ensure]
      raise ArgumentError, _('Ensure present/latest requires full path to file.  Example: /path/to/dir/pluginName-1.0.0.zip') unless is_zip
      install_from_file
    end

    if %r{^[\d.]+\d$}.match?(@resource[:ensure])
      raise ArgumentError, _('Ensure version requires path to repository.  Example: /path/to/repo_dir') if is_zip
      install_from_repo
    end
    # rubocop:enable GuardClause
  end

  def latest
    # the 'latest' version is extracted from the source file
    # because there is no other way to know what 'latest' means
    parsed = %r{([a-zA-Z]+)-([\d.]+\d)\.zip}.match(@resource[:source])
    raise ArgumentError, _('Source file does not match expected format.  Example: /path/to/dir/pluginName-1.0.0.zip') if parsed.nil?
    _plugin_name, version = parsed.captures
    version
  end

  def update
    uninstall
    install
  end

  def uninstall
    # remove the plugin, ignore failures
    execute([command(:osd_plugin), '--allow-root', 'remove', '--quiet', @resource[:name]])
  rescue Puppet::ExecutionFailure => e
    # plugin remove returns 74 if plugin not installed
    Puppet.debug(e.message)
  end

  private

  def install_from_repo
    # constructs the plugin/url ourselves based on :name and :ensure parameters
    repo = @resource[:source].delete_suffix('/')
    unless repo.slice(0, 4) == 'http'
      repo = "file://#{repo}"
    end
    plugin_file = "#{repo}/#{@resource[:name]}-#{@resource[:ensure]}.zip"
    execute([command(:osd_plugin), '--allow-root', 'install', '--quiet', plugin_file])
    nil
  end

  def install_from_file
    # constructs the plugin/url based on what is provided by the :source parameter
    plugin_file = @resource[:source]
    unless plugin_file.slice(0, 4) == 'http'
      plugin_file = "file://#{plugin_file}"
    end
    execute([command(:osd_plugin), '--allow-root', 'install', '--quiet', plugin_file])
    nil
  end
end
