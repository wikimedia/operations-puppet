require 'spec_helper'

describe 'osm', :type => :class do
    let(:params) do {
        :ensure           => 'present',
        }
    end

    context 'ensure present' do
        it { should contain_package('osm2pgsql').with_ensure('present') }
        it { should contain_package('osmosis').with_ensure('present') }
    end
end

describe 'osm', :type => :class do
    let(:params) do {
        :ensure           => 'absent',
        }
    end

    context 'ensure absent' do
        it { should contain_package('osm2pgsql').with_ensure('absent') }
        it { should contain_package('osmosis').with_ensure('absent') }
    end
end
