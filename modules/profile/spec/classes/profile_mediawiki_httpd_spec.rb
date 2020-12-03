require_relative '../../../../rake_modules/spec_helper'

describe 'profile::mediawiki::httpd' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:pre_condition) {
        [
          'class mediawiki::users($web="www-data"){ notice($web) }',
          'include mediawiki::users'
        ]
      }
      context "default parameters" do
        it { is_expected.to  compile.with_all_deps }
        it { is_expected.to contain_class('httpd')
                              .with_period('daily')
                              .with_rotate(30)
        }
        it { is_expected.to contain_file('/etc/apache2/conf-available/50-worker.conf')
                              .with_content(/MaxRequestWorkers\s+50/)
        }
      end
      context "with workers_limit = 5" do
        let(:params){ {:workers_limit => 5} }
        it { is_expected.to contain_file('/etc/apache2/conf-available/50-worker.conf')
                              .with_content(/MaxRequestWorkers\s+5/)
        }
      end
    end
  end
end
