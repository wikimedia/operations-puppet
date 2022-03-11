require_relative '../../../../rake_modules/spec_helper'  # Magic include which takes care of some custom WMF hacks

# The string below needs to match the class you plan to test
describe 'profile::puppet_compiler' do
  # WMFConfig.test_on this returns a hash of operating system facts sets (from facterdb) to test on
  # by default WMFConfig.test_on should return a hash of currently supported debian releases
  # however uoi can also use WMFConfig.test_on(int min, int max)
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      # mock facts are provided by the facterdb project (https://github.com/voxpupuli/facterdb)
      # and some custom ones added via rake_modules/default_facts.yml
      let(:facts) { os_facts }
      # for most purposes one can consider node_params as a way to mock global parameters
      let(:node_params) do
        {
          # 'realm' => 'labs'  # use to test labs specific hiera lookups
          'role' => 'mediawiki/appserver'  # use to test c$role::mediawiki::appserver
        }
      end
      let(:params) do
          {
            'class_parameter' => 'override_value'  # used to override default value for the `class_parameter` parameter
          }
      end
      # :pre_condition is used to run some puppet code before tests often used to mock difficult classes
      # mostly shouldn't be needed with our environment (assuming the include above)
      # let(:pre_condition) do
      #   " class apt {}
      #     include apt
      #   "
      # end
      describe 'test compilation with default parameters' do
        # This is the most basic test and ensures the catalog actully compiles
        it { is_expected.to compile.with_all_deps }
      end
      describe "test overiding a custom fact" do
        super().merge(ipaddress: '192.0.2.1')
        # The following test that catalouge
        it do
          is_expected.to contain_file('/etc/resolve.conf')
            .with_content(/192\.0\.2\.1/)
        end
        # examples of other resouces and hwo to test parameters
        # ensure we have a user with ensure set to present and uid set to 42
        it { is_expected.to contain_user('bob').with_ensure('present').with_uid(42) }
        # Same as above but using the with method with a hash
        it { is_expected.to contain_user('bob').with(ensure: 'present', uid: 42) }
        it do
          # if an statament spans multiple lines use the `it do .. end` syntax over `it { ... }`
          # here we tests a puppet resource http::vhost, notice the double underscore instead of ::
          is_expected.to contain_http__vhost('www.example.org')
            .with_content(/ServerName\s+www.example.org/) # you can also ensure things are absent
            .without_content(/ServerName\s+localhost/)    # or just make sure a parameter is not set at all
            .without_source
        end
      end
      describe "test overiding a parameter" do
        let(:params) { super().merge(class_parameter: 'foobar') }
        it { is_expected.to contain_file('/etc/foobar').with_content(/foobar/) }
      end
    end
  end
end
