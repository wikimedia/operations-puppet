# encoding: utf-8

require 'spec_helper'

require 'puppet/external/nagios'

describe 'Nagios' do
  context 'parser' do
    NONESCAPED_SEMICOLON_COMMENT = <<-'EOL'.freeze
define host{
    use                     linux-server            ; Name of host template to use
    host_name               localhost
    alias                   localhost
    address                 127.0.0.1
    }

define command{
  command_name  notify-host-by-email
  command_line  /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /usr/bin/mail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$
  }
EOL

    LINE_COMMENT_SNIPPET = <<-'EOL'.freeze

# This is a comment starting at the beginning of a line

define command{

# This is a comment starting at the beginning of a line

  command_name  command_name

# This is a comment starting at the beginning of a line
  ## --PUPPET_NAME-- (called '_naginator_name' in the manifest)                command_name

  command_line  command_line

# This is a comment starting at the beginning of a line

  }

# This is a comment starting at the beginning of a line

EOL

    LINE_COMMENT_SNIPPET2 = <<-'EOL'.freeze
      define host{
          use                     linux-server            ; Name of host template to use
          host_name               localhost
          alias                   localhost
          address                 127.0.0.1
          }
define command{
  command_name  command_name2
  command_line  command_line2
  }
EOL

    UNKNOWN_NAGIOS_OBJECT_DEFINITION = <<-'EOL'.freeze
      define command2{
        command_name  notify-host-by-email
        command_line  /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /usr/bin/mail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$
        }
    EOL

    MISSING_CLOSING_CURLY_BRACKET = <<-'EOL'.freeze
      define command{
        command_name  notify-host-by-email
        command_line  /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /usr/bin/mail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$
    EOL

    ESCAPED_SEMICOLON = <<-'EOL'.freeze
        define command {
            command_name  nagios_table_size
            command_line $USER3$/check_mysql_health --hostname localhost --username nagioschecks --password nagiosCheckPWD --mode sql --name "SELECT ROUND(Data_length/1024) as Data_kBytes from INFORMATION_SCHEMA.TABLES where TABLE_NAME=\"$ARG1$\"\;" --name2 "table size" --units kBytes -w $ARG2$ -c $ARG3$
        }
    EOL

    POUND_SIGN_HASH_SYMBOL_NOT_IN_FIRST_COLUMN = <<-'EOL'.freeze
        define command {
            command_name  notify-by-irc
            command_line /usr/local/bin/riseup-nagios-client.pl "$HOSTNAME$ ($SERVICEDESC$) $NOTIFICATIONTYPE$ #$SERVICEATTEMPT$ $SERVICESTATETYPE$ $SERVICEEXECUTIONTIME$s $SERVICELATENCY$s $SERVICEOUTPUT$ $SERVICEPERFDATA$"
        }
    EOL

    ANOTHER_ESCAPED_SEMICOLON = <<-EOL.freeze
define command {
\tcommand_line                   LC_ALL=en_US.UTF-8 /usr/lib/nagios/plugins/check_haproxy -u 'http://blah:blah@$HOSTADDRESS$:8080/haproxy?stats\\;csv'
\tcommand_name                   check_haproxy
}
EOL

    UNICODE_NAGIOS_CONTACT = <<-EOL.freeze
define contact {
\talias                          Paul Tötterman
\tcontact_name                   ptman
}
EOL

    it 'parses without error' do
      parser = Nagios::Parser.new
      expect {
        parser.parse(NONESCAPED_SEMICOLON_COMMENT)
      }.not_to raise_error
    end

    context 'when parsing a statement' do
      parser =  Nagios::Parser.new
      results = parser.parse(NONESCAPED_SEMICOLON_COMMENT)
      results.each do |obj|
        it 'has the proper base type' do
          expect(obj).to be_a_kind_of(Nagios::Base)
        end
      end
    end

    it 'raises an error when an incorrect object definition is present' do
      parser = Nagios::Parser.new
      expect {
        parser.parse(UNKNOWN_NAGIOS_OBJECT_DEFINITION)
      }.to raise_error Nagios::Base::UnknownNagiosType
    end

    it 'raises an error when syntax is not correct' do
      parser = Nagios::Parser.new
      expect {
        parser.parse(MISSING_CLOSING_CURLY_BRACKET)
      }.to raise_error Nagios::Parser::SyntaxError
    end

    context "when encoutering ';'" do
      it 'does not throw an exception' do
        parser = Nagios::Parser.new
        expect {
          parser.parse(ESCAPED_SEMICOLON)
        }.not_to raise_error
      end

      it 'ignores it if it is a comment' do
        parser =  Nagios::Parser.new
        results = parser.parse(NONESCAPED_SEMICOLON_COMMENT)
        expect(results[0].use).to eql('linux-server')
      end

      it 'parses correctly if it is escaped' do
        parser =  Nagios::Parser.new
        results = parser.parse(ESCAPED_SEMICOLON)
        expect(results[0].command_line).to eql('$USER3$/check_mysql_health --hostname localhost --username nagioschecks --password nagiosCheckPWD --mode sql --name "SELECT ROUND(Data_length/1024) as Data_kBytes from INFORMATION_SCHEMA.TABLES where TABLE_NAME=\\"$ARG1$\\";" --name2 "table size" --units kBytes -w $ARG2$ -c $ARG3$') # rubocop:disable Metrics/LineLength
      end
    end

    context "when encountering '#'" do
      it 'does not throw an exception' do
        parser = Nagios::Parser.new
        expect {
          parser.parse(POUND_SIGN_HASH_SYMBOL_NOT_IN_FIRST_COLUMN)
        }.not_to raise_error
      end

      it 'ignores it at the beginning of a line' do
        parser =  Nagios::Parser.new
        results = parser.parse(LINE_COMMENT_SNIPPET)
        expect(results[0].command_line).to eql('command_line')
      end

      it 'lets it go anywhere else' do
        parser =  Nagios::Parser.new
        results = parser.parse(POUND_SIGN_HASH_SYMBOL_NOT_IN_FIRST_COLUMN)
        expect(results[0].command_line).to eql("/usr/local/bin/riseup-nagios-client.pl \"$HOSTNAME$ ($SERVICEDESC$) $NOTIFICATIONTYPE$ \#$SERVICEATTEMPT$ $SERVICESTATETYPE$ $SERVICEEXECUTIONTIME$s $SERVICELATENCY$s $SERVICEOUTPUT$ $SERVICEPERFDATA$\"") # rubocop:disable Metrics/LineLength
      end
    end

    context "when encountering ';' again" do
      it 'does not throw an exception' do
        parser = Nagios::Parser.new
        expect {
          parser.parse(ANOTHER_ESCAPED_SEMICOLON)
        }.not_to raise_error
      end

      it 'parses correctly' do
        parser =  Nagios::Parser.new
        results = parser.parse(ANOTHER_ESCAPED_SEMICOLON)
        expect(results[0].command_line).to eql("LC_ALL=en_US.UTF-8 /usr/lib/nagios/plugins/check_haproxy -u 'http://blah:blah@$HOSTADDRESS$:8080/haproxy?stats;csv'")
      end
    end

    it 'is idempotent' do
      parser = Nagios::Parser.new
      src = ANOTHER_ESCAPED_SEMICOLON.dup
      results = parser.parse(src)
      nagios_type = Nagios::Base.create(:command)
      nagios_type.command_name = results[0].command_name
      nagios_type.command_line = results[0].command_line
      expect(nagios_type.to_s).to eql(ANOTHER_ESCAPED_SEMICOLON)
    end

    context 'when reading UTF8 values' do
      it 'is converted to ASCII_8BIT for ruby 1.9 / 2.0', if: RUBY_VERSION < '2.1.0' && String.method_defined?(:encode) do
        parser = Nagios::Parser.new
        results = parser.parse(UNICODE_NAGIOS_CONTACT)
        expect(results[0].alias.encoding).to eq(Encoding::ASCII_8BIT)
        expect(results[0].alias).to eq('Paul Tötterman'.force_encoding(Encoding::ASCII_8BIT))
      end

      it 'must not be converted for ruby >= 2.1', if: RUBY_VERSION >= '2.1.0' do
        parser = Nagios::Parser.new
        results = parser.parse(UNICODE_NAGIOS_CONTACT)
        expect(results[0].alias.encoding).to eq(Encoding::UTF_8)
      end
    end
  end

  context 'generator' do
    it "escapes ';'" do
      param = '$USER3$/check_mysql_health --hostname localhost --username nagioschecks --password nagiosCheckPWD --mode sql --name "SELECT ROUND(Data_length/1024) as Data_kBytes from INFORMATION_SCHEMA.TABLES where TABLE_NAME=\"$ARG1$\";" --name2 "table size" --units kBytes -w $ARG2$ -c $ARG3$' # rubocop:disable Metrics/LineLength
      nagios_type = Nagios::Base.create(:command)
      nagios_type.command_line = param
      expect(nagios_type.to_s).to eql("define command {\n\tcommand_line                   $USER3$/check_mysql_health --hostname localhost --username nagioschecks --password nagiosCheckPWD --mode sql --name \"SELECT ROUND(Data_length/1024) as Data_kBytes from INFORMATION_SCHEMA.TABLES where TABLE_NAME=\\\"$ARG1$\\\"\\;\" --name2 \"table size\" --units kBytes -w $ARG2$ -c $ARG3$\n}\n") # rubocop:disable Metrics/LineLength
    end

    it "escapes ';' if it is not already the case" do
      param = "LC_ALL=en_US.UTF-8 /usr/lib/nagios/plugins/check_haproxy -u 'http://blah:blah@$HOSTADDRESS$:8080/haproxy?stats;csv'"
      nagios_type = Nagios::Base.create(:command)
      nagios_type.command_line = param
      expect(nagios_type.to_s).to eql("define command {\n\tcommand_line                   LC_ALL=en_US.UTF-8 /usr/lib/nagios/plugins/check_haproxy -u 'http://blah:blah@$HOSTADDRESS$:8080/haproxy?stats\\;csv'\n}\n") # rubocop:disable Metrics/LineLength
    end

    it 'is idempotent' do
      param = '$USER3$/check_mysql_health --hostname localhost --username nagioschecks --password nagiosCheckPWD --mode sql --name "SELECT ROUND(Data_length/1024) as Data_kBytes from INFORMATION_SCHEMA.TABLES where TABLE_NAME=\"$ARG1$\";" --name2 "table size" --units kBytes -w $ARG2$ -c $ARG3$' # rubocop:disable Metrics/LineLength
      nagios_type = Nagios::Base.create(:command)
      nagios_type.command_line = param
      parser =  Nagios::Parser.new
      results = parser.parse(nagios_type.to_s)
      expect(results[0].command_line).to eql(param)
    end

    it 'accepts FixNum params and convert to string' do
      param = 1
      nagios_type = Nagios::Base.create(:serviceescalation)
      nagios_type.first_notification = param
      parser =  Nagios::Parser.new
      results = parser.parse(nagios_type.to_s)
      expect(results[0].first_notification).to eql(param.to_s)
    end
  end

  context 'resource types' do
    Nagios::Base.eachtype do |name, nagios_type|
      puppet_type = Puppet::Type.type("nagios_#{name}")

      it "should have a valid type for #{name}" do
        expect(puppet_type).not_to be_nil
      end

      next unless puppet_type

      context puppet_type do
        it 'is defined as a Puppet resource type' do
          expect(puppet_type).not_to be_nil
        end

        it 'has documentation' do
          expect(puppet_type.instance_variable_get('@doc')).not_to eq('')
        end

        it "should have #{nagios_type.namevar} as its key attribute" do
          expect(puppet_type.key_attributes).to eq([nagios_type.namevar])
        end

        it "should have documentation for its #{nagios_type.namevar} parameter" do
          expect(puppet_type.attrclass(nagios_type.namevar).instance_variable_get('@doc')).not_to be_nil
        end

        it 'has an ensure property' do
          expect(puppet_type).to be_validproperty(:ensure)
        end

        it 'has a target property' do
          expect(puppet_type).to be_validproperty(:target)
        end

        it 'has documentation for its target property' do
          expect(puppet_type.attrclass(:target).instance_variable_get('@doc')).not_to be_nil
        end

        [:owner, :group, :mode].each do |fileprop|
          it "should have a #{fileprop} parameter" do
            expect(puppet_type.parameters).to be_include(fileprop)
          end
        end

        nagios_type.parameters.reject { |param| param == nagios_type.namevar || param.to_s =~ %r{^[0-9]} }.each do |param|
          it "should have a #{param} property" do
            expect(puppet_type).to be_validproperty(param)
          end

          it "should have documentation for its #{param} property" do
            expect(puppet_type.attrclass(param).instance_variable_get('@doc')).not_to be_nil
          end
        end

        nagios_type.parameters.select { |param| param.to_s =~ %r{^[0-9]} }.each do |param|
          it "should have not have a #{param} property" do
            expect(puppet_type).not_to be_validproperty(:param)
          end
        end
      end
    end
  end
end
