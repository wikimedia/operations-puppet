# frozen_string_literal: true

require 'spec_helper'

describe 'concat::fragment' do
  shared_examples 'fragment' do |title, params|
    params = {} if params.nil?

    p = {
      content: nil,
      source: nil,
      order: 10,
    }.merge(params)

    let(:title) { title }
    let(:params) { params }
    let(:pre_condition) do
      "concat{ '#{p[:target]}': }"
    end

    it do
      is_expected.to contain_concat(p[:target])
    end
    it do
      is_expected.to contain_concat_file(p[:target])
    end
    it do
      is_expected.to contain_concat_fragment(title)
    end
  end

  context 'when title' do
    ['0', '1', 'a', 'z'].each do |title|
      it_behaves_like 'fragment', title, target: '/etc/motd',
                                         content: "content for #{title}"
    end
  end
  # title

  context 'when target =>' do
    ['./etc/motd', 'etc/motd', 'motd_header'].each do |target|
      context target do
        it_behaves_like 'fragment', target, target: '/etc/motd',
                                            content: "content for #{target}"
      end
    end

    context 'when false' do
      let(:title) { 'motd_header' }
      let(:params) { { target: false } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{parameter 'target' expects a .*String.*})
      end
    end
  end
  # target =>

  context 'when content =>' do
    ['', 'ashp is our hero'].each do |content|
      context content do
        it_behaves_like 'fragment', 'motd_header', content: content,
                                                   target: '/etc/motd'
      end
    end

    context 'when false' do
      let(:title) { 'motd_header' }
      let(:params) { { content: false, target: '/etc/motd' } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{expects a value of type Undef( or String|, String, or Deferred), got Boolean})
      end
    end
  end
  # content =>

  context 'when source =>' do
    ['', '/foo/bar', ['/foo/bar', '/foo/baz']].each do |source|
      context source do
        it_behaves_like 'fragment', 'motd_header',           source: source,
                                                             target: '/etc/motd'
      end
    end

    context 'when false' do
      let(:title) { 'motd_header' }
      let(:params) { { source: false, target: '/etc/motd' } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{parameter 'source' expects a .*String.*Array.*})
      end
    end
  end
  # source =>

  context 'when order =>' do
    ['', '42', 'a', 'z'].each do |order|
      context "'#{order}'" do
        it_behaves_like 'fragment', 'motd_header',           order: order,
                                                             target: '/etc/motd'
      end
    end

    context 'when false' do
      let(:title) { 'motd_header' }
      let(:params) { { order: false, target: '/etc/motd' } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{Evaluation Error.*expects.*Boolean.*})
      end
    end

    context 'when 123:456' do
      let(:title) { 'motd_header' }
      let(:params) { { order: '123:456', target: '/etc/motd' } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{cannot contain})
      end
    end
    context 'when 23/456' do
      let(:title) { 'motd_header' }
      let(:params) { { order: '123/456', target: '/etc/motd' } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{cannot contain})
      end
    end
    context 'when 123\n456' do
      let(:title) { 'motd_header' }
      let(:params) { { order: "123\n456", target: '/etc/motd' } }

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{cannot contain})
      end
    end
  end
  # order =>

  context 'with more than one content source' do
    context 'with source and content' do
      let(:title) { 'motd_header' }
      let(:params) do
        {
          target: '/etc/motd',
          source: '/foo',
          content: 'bar',
        }
      end

      it 'fails' do
        expect { catalogue }.to raise_error(Puppet::Error, %r{Can\'t use \'source\' and \'content\' at the same time}m)
      end
    end
  end
  # more than one content source
end
