require 'spec_helper'

describe 'bacula::client::job' do
    let(:title) { 'something' }
    let(:params) { {
        :fileset      => 'root',
        :jobdefaults  => 'testdefaults',
        }
    }
end
