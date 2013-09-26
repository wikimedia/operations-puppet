#!/usr/bin/env ruby
require 'helpers'

case ARGV.shift
when "list-roles"
    puts "Available roles:\n\n"
    enabled = roles_enabled
    roles_available.each { |role|
        prefix = enabled.include?(role) ? '*' : ' '
        puts "#{prefix} #{role}"
    }
    puts "\nRoles marked with '*' are enabled."
    puts 'Use "labsvagrant enable-role" & "labsvagrant disable-role" to customize.'

when "reset-roles"
    if not ARGV.empty? or ['-h', '--help'].include? ARGV.first
        puts 'Disable all optional roles.'
        puts 'USAGE: labsvagrant reset-roles'
    end
    update_roles []
    puts "All roles were disabled."
    puts COMMIT_CHANGES
when "enable-role"
    if ARGV.empty? or ['-h', '--help'].include? ARGV.first
        puts 'Enable an optional role (run "labsvagrant list-roles" for a list).'
        puts 'USAGE: labsvagrant enable-role ROLE'
        return 0
    end
    avail = roles_available
    ARGV.each do |r|
        if not avail.include? r
            puts "'#{r}' is not a valid role."
            return 1
        end
    end
    update_roles(roles_enabled + ARGV)

when "disable-role"
    if ARGV.empty? or ['-h', '--help'].include? ARGV.first
        puts 'Disable one or more optional roles.'
        puts 'USAGE: labsvagrant disable-role ROLE'
        return 0
    end
    enabled = roles_enabled
    ARGV.each do |r|
        if not enabled.include? r
            puts "'#{r}' is not enabled."
        end
    end
    update_roles(enabled - ARGV)
when "provision"
    puppet_path = "/vagrant/puppet"
    exec "puppet apply \
        --modulepath #{puppet_path}/modules \
        --manifestdir #{puppet_path}/manifests \
        --templatedir #{puppet_path}/templates \
        --fileserverconfig #{puppet_path}/extra/fileserver.conf \
        --config_version #{puppet_path}/extra/config-version \
        --verbose \
        --logdest console \
        --detailed-exitcodes \
        #{puppet_path}/manifests/site.pp"

end
