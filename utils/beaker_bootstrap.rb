#!/usr/bin/ruby
# SPDX-License-Identifier: Apache-2.0
# This script is run by beaker inside the created docker image
require 'fileutils'
require 'open-uri'
require 'socket'
require 'yaml'

HOSTNAME = ARGV[0]

def write_hiera
  # Write out a custome hiera file with the beaker overrides taking precedence
  hiera_config = YAML.load_file(File.join(__dir__, '../modules/puppetmaster/files/production.hiera.yaml'))
  hiera_config['hierarchy'].insert(0, {'name' => 'beaker overrides', 'path' => 'beaker.yaml'})
  File.open('/etc/puppet/hiera.yaml', 'w') { |f| YAML.dump(hiera_config, f) }
end

def write_interfaces
  # Write out an interfaces file, this is needed so that augeas can parse and update the file
  default_route = `ip route list default`.strip.split
  default_iface = default_route[-1]
  default_route_addr = default_route[2]
  iface = Socket.getifaddrs.select { |i| i.name == default_iface && i.addr.ipv4? }[0]
  content = <<~IFACE
  iface #{default_iface} inet static
    address #{iface.addr.ip_address}
    netmask #{iface.netmask.ip_address}
    gateway #{default_route_addr}
  IFACE
  File.open('/etc/network/interfaces', 'w') { |f| f.write(content) }
end

def fix_sorces_list
  # Add contrib and none-free to the sources list
  orig_content = File.open('/etc/apt/sources.list').read
  File.open('/etc/apt/sources.list', 'w') do |sources_list|
    orig_content.each_line do |line|
      if line.start_with?("deb\s") && !line.include?('apt.wikimedia.org')
        ['contrib', 'non-free'].each do |component|
          line = "#{line.chomp} #{component}\n" unless line.include?(component)
        end
      end
      sources_list.write(line)
    end
  end
  `apt-get update -y`
end

def update_repo(repo_dir, repo_url, sha1_url)
  # Check out a specific repo
  sha1 = open(sha1_url).read
  unless File.directory?(repo_dir)
    FileUtils.mkdir_p(File.dirname(repo_dir))
    `git clone #{repo_url} #{repo_dir}`
  end
  `git -C #{repo_dir} checkout #{sha1}`
end

def sync_puppet_dirs(prod_source, private_source = '/etc/puppet/private')
  # link all directories into the correct folder.
  modules_dir = '/etc/puppet/code/modules'
  hieradata_dir = '/etc/puppet/hieradata'
  FileUtils.rm_rf(Dir["#{modules_dir}/*"])
  FileUtils.mkdir_p(modules_dir)
  Dir[
    "#{prod_source}/modules/*",
    "#{prod_source}/vendor_modules/*",
    "#{private_source}/modules/*"
  ].each do |mod|
    File.symlink(mod, File.join(modules_dir, File.basename(mod)))
  end
  FileUtils.rm_rf(hieradata_dir)
  File.symlink(File.join(prod_source, 'hieradata'), hieradata_dir)
end

def generate_ssl_certs(hostname)
  # Generate some puppet certs for the hostname being tested
  FileUtils.rm_rf('/var/lib/puppet/ssl')
  `/usr/bin/puppet cert generate '#{hostname}'`
end

# enable v6
`sysctl net.ipv6.conf.all.disable_ipv6=0`
# update the hostname
`hostname #{HOSTNAME}`
fix_sorces_list
write_interfaces
write_hiera
update_repo(
  '/etc/puppet/private',
  'https://gerrit.wikimedia.org/r/labs/private',
  'https://config-master.wikimedia.org/labsprivate-sha1.txt'
)
# Currently this repo is not used however we may use it in the future to
# provide something similar to pcc
update_repo(
  '/srv/workspace/puppet',
  'https://gerrit.wikimedia.org/r/operations/puppet',
  'https://config-master.wikimedia.org/puppet-sha1.txt'
)
# production is mounted by docker and is the working directory where the beate command is run
sync_puppet_dirs('/production')
generate_ssl_certs(HOSTNAME)
