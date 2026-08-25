# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

# rubocop:disable Style/RegexpLiteral

def it_handles_log4j(facts)
    codename = facts[:os]['distro']['codename']
    case codename
    when 'bookworm'
      it "contains log4j on #{codename}" do
        should contain_file_line('zookeeper-log4j-classpath')
          .with_line(%r%^CLASSPATH=.*slf4j-log4j%)
      end
    end
end

describe 'zookeeper::server' do
  on_supported_os(WMFConfig.test_on(11, 13)).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        """
        include zookeeper
        """
      end

      it { is_expected.to compile }

      context 'class path' do
        case facts[:os]['distro']['codename']
        when 'bookworm'
            it 'contains zookeeper.jar' do
              should contain_file_line('zookeeper-log4j-classpath')
                .with_line(%r%^CLASSPATH=.*/zookeeper.jar%)
            end
        end
        it_handles_log4j(facts)
      end

      context 'TLS enabled' do
        let(:params) { {
          :enable_tls => true,
        } }
        it 'contains netty' do
          should contain_file_line('append-netty-classpath')
            .with_line(%r%^CLASSPATH=.*netty-common.jar%)
        end
        it_handles_log4j(facts)
      end
    end
  end
end
