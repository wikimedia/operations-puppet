class SpecDependencies
  # Finds all specs to run based on the changed modules.

  def initialize
    @deps = {}
    FileList["modules/*/.fixtures.yml"].each do |file|
      module_name = module_from_filename(file)
      symlinks = YAML.safe_load(File.open(file))['fixtures']['symlinks'].keys.select{ |x| x != module_name }
      symlinks.each do |dependency|
        @deps[dependency] ||= []
        @deps[dependency] << module_name
      end
    end
  end

  def specs_to_run(filelist)
    specs = Set.new
    modules = modules_modified(filelist)
    return [] unless modules
    modules.each do |mod|
      next unless Dir.exists?("modules/#{mod}/spec")
      specs.add(mod)
      if @deps.include?mod
        @deps[mod].each{ |m| specs.add(m) }
      end
    end
    specs.to_a
  end

  private

  def modules_modified(filelist)
    modules = Set.new
    filelist.each do |file|
      module_name = module_from_filename(file)

      modules.add(module_name) if module_name
    end
    modules.to_a
  end

  def module_from_filename(name)
    if %r{modules/([^/]+)} =~ name
      Regexp.last_match(1)
    else
      nil
    end
  end
end
