Gem.post_install do |installer|
  gem_name = plugin_name = installer.spec.name

  if gem_name.start_with?('antfarm-')
    plugin_name.slice!('antfarm-')

    require 'antfarm'
    require 'fileutils'

    plugin_dir = "#{Antfarm::Helpers.user_plugins_dir}/#{plugin_name}"
    FileUtils.mkdir(plugin_dir, :mode => 0755)

    Dir["#{installer.dir}/*.rb", "#{installer.dir}/man"].each do |file|
      FileUtils.cp_r(file, plugin_dir)
    end
  end
end

Gem.post_uninstall do |uninstaller|
  gem_name = plugin_name = uninstaller.spec.name

  if gem_name.start_with?('antfarm-')
    plugin_name.slice!('antfarm-')

    require 'antfarm'
    require 'fileutils'

    plugin_dir = "#{Antfarm::Helpers.user_plugins_dir}/#{plugin_name}"
    FileUtils.rm_rf(plugin_dir)
  end
end
