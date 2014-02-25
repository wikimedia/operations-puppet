require 'spec_helper'

describe 'postgresql::postgis', :type => :class do
    let(:params) { {
        :pgversion => '9.1',
        :ensure => 'present',
        }
    }

    context 'ensure present' do
        it { should contain_package('postgresql-9.1-postgis').with_ensure('present') }
    end
end

describe 'postgresql::postgis', :type => :class do
    let(:params) { {
        :pgversion => '9.1',
        :ensure => 'absent',
        }
    }

    context 'ensure absent' do
        it { should contain_package('postgresql-9.1-postgis').with_ensure('absent') }
    end
end
