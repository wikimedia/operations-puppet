require 'spec_helper'

describe 'servermon', :type => :class do
    let(:params) { {
        :ensure    => 'present',
        :directory => '/tmp/test',
        }
    }

    it { should contain_package('python-django') }
    it { should contain_package('python-django-south') }
    it { should contain_package('python-ldap') }
    it { should contain_package('python-ipy') }
    it { should contain_package('python-whoosh') }

    it { should contain_package('gunicorn') }
    it { should contain_service('gunicorn') }
    it { should contain_file('/etc/gunicorn.d/servermon').with_content(/\/tmp\/test/) }
end
