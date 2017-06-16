# Puppet reporter to update servermon database
#
# Based on https://serverfault.com/questions/515455/how-do-i-make-puppet-post-facts-after-run
#
# This report handler uses the puppet config from puppet.conf to get the
# active_record database settings and connect to it and issue commands to update
# it in case the used storeconfigs_backend is puppetdb. This is useful for the
# servermon software (https://github.com/servermon/servermon), at least until it
# is updated to support puppetdb directly. The manual SQL command approach was
# chosen instead of reusing the active record approach supported by the rails
# framework of puppet, since it would not be initialized when
# storeconfig_backend = puppetdb
# NOTE: This is probably quite inefficient, but let's evaluate first
#
# NOTE: On 2017-05-05 an inefficiency was indeed found. The fix was to alter the
# puppet schema by changing the index on fact_values table. The command issued:
#
# ALTER TABLE fact_values drop index index_fact_values_on_host_id, add index
# index_fact_values_on_host_id(host_id,fact_name_id);
#
# Copyright 2016 Alexandros Kosiaris and Wikimedia Foundation.
# License http://www.apache.org/licenses/LICENSE-2.0

require 'puppet'
require 'mysql'
require 'English'

Puppet::Reports.register_report(:servermon) do
    desc 'Update facts of a servermon database'

    def process
        # Starting with puppet 4 active record settings no longer exist. So, parse
        # them from the configuration file. Previously we could just query the
        # Puppet object
        config = File.open('/etc/puppet/puppet.conf')
        lines = config.readlines
        config.close
        # Setting first our variables to avoid scoping problems
        dbserver = nil
        dbuser = nil
        dbpassword = nil
        log_level = 'info'
        lines.each do |line|
          case
          when line =~ /^dbserver[[:space:]]*=[[:space:]]*(.*)$/
            dbserver = $LAST_MATCH_INFO[1]
          when line =~ /^dbuser[[:space:]]*=[[:space:]]*(.*)$/
            dbuser = $LAST_MATCH_INFO[1]
          when line =~ /^dbpassword[[:space:]]*=[[:space:]]*(.*)$/
            dbpassword = $LAST_MATCH_INFO[1]
          when line =~ /^log_level[[:space:]]*=[[:space:]]*(.*)$/
            log_level = $LAST_MATCH_INFO[1]
          end
        end
        # We failed to get all of our configs, let's bail early to avoid causing
        # puppet issues
        unless dbserver && dbuser && dbpassword && log_level
          return true
        end
        begin
            con = Mysql.new dbserver, dbuser, dbpassword, 'puppet'
            # First we try to update the host, if it fails, insert it
            update_host = "UPDATE hosts SET \
            environment = '#{environment}', \
            updated_at = '#{time}', \
            last_compile = '#{time}' \
            WHERE name='#{host}'"
            con.query(update_host)
            if con.affected_rows.zero?
                insert_host = "INSERT INTO hosts(
                name, environment, last_compile, updated_at, created_at) \
                VALUES('#{host}', '#{environment}', '#{time}', '#{time}', '#{time}')"
                con.query(insert_host)
            end
            # Now we know the host is there, get the id
            query = "SELECT id from hosts \
            WHERE name='#{host}'"
            rs = con.query(query)
            host_id = rs.fetch_row[0]
            if log_level == 'debug'
                puts "Got host: #{host} with id: #{host_id}"
            end

            # if facts file found, read it and update facts for host:
            if File.exists?("#{Puppet[:vardir]}/yaml/facts/#{host}.yaml")
                node_facts = YAML.load_file("#{Puppet[:vardir]}/yaml/facts/#{host}.yaml")
                # We got a Ruby object, get the values attributes and walk it
                # This part of the code causes highly concurrent queries to the
                # DB, so extra care is taken to avoid LOCKs, deadlocks etc
                node_facts.values.each do |key, value|
                    string_value = value.to_s
                    # First try to see if the fact_name already exists
                    con.query('BEGIN')
                    select_fact_name = "SELECT id from fact_names \
                    WHERE name='#{key}'"
                    if log_level == 'debug'
                        puts(select_fact_name)
                    end
                    rs = con.query(select_fact_name)
                    # So we need to insert a fact_name
                    if rs.num_rows.zero?
                        insert_fact_name = "INSERT INTO fact_names(name, updated_at, created_at) \
                        VALUES('#{key}', '#{time}', '#{time}')"
                        if log_level == 'debug'
                            puts(insert_fact_name)
                        end
                        con.query(insert_fact_name)
                        # Should have been inserted, fetch it
                        rs = con.query(select_fact_name)
                        fact_id = rs.fetch_row[0]
                    else
                        fact_id = rs.fetch_row[0]
                        if log_level == 'debug'
                            puts "Got fact: #{key} with id: #{fact_id}"
                        end
                    end
                    con.query('COMMIT')
                    # Now try to update the fact_value, it is fails, insert it
                    update_fact_value = "UPDATE fact_values SET \
                    updated_at = '#{time}', \
                    value = '#{string_value}' \
                    WHERE fact_name_id=#{fact_id} AND host_id=#{host_id}"
                    if log_level == 'debug'
                        puts(update_fact_value)
                    end
                    con.query(update_fact_value)
                    # rubocop:disable Style/Next
                    if con.affected_rows.zero?
                        insert_fact_value = "INSERT INTO fact_values( \
                        value,fact_name_id,host_id,updated_at,created_at) \
                        VALUES('#{string_value}', #{fact_id}, #{host_id}, '#{time}', '#{time}')"
                        if log_level == 'debug'
                            puts(insert_fact_value)
                        end
                        con.query(insert_fact_value)
                    end
                    # rubocop:enable Style/Next
                end
            end
        rescue Mysql::Error => e
            puts "Mysql error: #{e.errno}, #{e.error}"
            puts e.errno
            puts e.error
        # rubocop:disable Lint/RescueException
        rescue Exception => e
            puts "Exception caught: #{e.errno}, #{e.error}"
        # rubocop:enable Lint/RescueException
        ensure
            con.close if con
        end
    end
end
