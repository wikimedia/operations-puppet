shared_examples_for 'all parsedfile providers' do |provider, *files|
  if files.empty?
    files = my_fixtures
  end

  files.flatten.each do |file|
    it "rewrites #{file} reasonably unchanged" do
      allow(provider).to receive(:default_target).and_return(file)
      provider.prefetch

      text = provider.to_file(provider.target_records(file))
      text.gsub!(%r{^# HEADER.+\n}, '')

      oldlines = File.readlines(file)
      newlines = text.chomp.split "\n"
      oldlines.zip(newlines).each do |old, new|
        expect(new.gsub(%r{\s+}, '')).to eq(old.chomp.gsub(%r{\s+}, ''))
      end
    end
  end
end
