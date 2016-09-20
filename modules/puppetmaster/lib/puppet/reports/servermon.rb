# Puppet reporter to update servermon database
#
# Based on https://serverfault.com/questions/515455/how-do-i-make-puppet-post-facts-after-run
#
# Copyright © 2016 Alexandros Kosiaris and Wikimedia Foundation.
# License http://www.apache.org/licenses/LICENSE-2.0

require 'puppet'
require 'pp'
require 'mysql'

Puppet::Reports.register_report(:servermon) do
    desc 'Update facts of a servermon database'


    def process
        # Get our users from the configuration
        dbserver = Puppet[:dbserver]
        dbuser = Puppet[:dbuser]
        dbpassword = Puppet[:dbpassword]
        begin
            con = Mysql.new dbserver, dbuser, dbpassword, 'puppet'
            # First we update the host
            query = "UPDATE hosts SET \
            environment = '#{self.environment}', \
            updated_at = '#{self.time}', \
            last_compile = '#{self.time}' \
            WHERE name='#{self.host}'"
            rs = con.query(query)
            query = "SELECT id from hosts \
            WHERE name='#{self.host}'"
            rs = con.query(query)
            host_id = rs.fetch_row[0]
            puts "Got host: #{self.host} with id: #{host_id}"

            # if facts file found, read it and update facts for host:
            if File.exists?("#{Puppet[:vardir]}/yaml/facts/#{self.host}.yaml")
                node_facts = YAML.load_file("#{Puppet[:vardir]}/yaml/facts/#{self.host}.yaml")
                # We got a Ruby object, get the values attributes and walk it
                node_facts.values.each do |key, value|
                    # First update the fact_names table
                    update_fact_name = "UPDATE fact_names SET \
                    updated_at = '#{self.time}' \
                    WHERE name='#{key}'"
                    puts(update_fact_name)
                    rs = con.query(update_fact_name)
                    query = "SELECT id from fact_names \
                    WHERE name='#{key}'"
                    rs = con.query(query)
                    pp(rs)
                    fact_id = rs.fetch_row[0]
                    puts "Got fact: #{key} with id: #{fact_id}"
                    update_fact_value = "UPDATE fact_values SET \
                    updated_at = '#{self.time}', \
                    value = '#{value}' \
                    WHERE fact_name_id=#{fact_id} AND host_id=#{host_id}"
                    puts(update_fact_value)
                    rs = con.query(update_fact_value)
                    pp(rs)
                end
            end
        rescue Mysql::Error => e
            puts e.errno
            puts e.error
        ensure
            con.close if con
        end
    end
end
