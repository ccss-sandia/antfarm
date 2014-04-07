# Look for Gems being installed that start with `antfarm-` and assume they're
# ANTFARM plugins. Determine the name of the plugin (everything after the
# `antfarm-`), create a directory using the plugin name in the current user's
# plugin directory, and copy any files in the root directory of the Gem that
# are Ruby files as well as the `man` directory to the new plugin directory.
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

# Look for Gems being uninstalled that start with `antfarm-` and assume they're
# ANTFARM plugins. Determine the name of the plugin (everything after the
# `antfarm-`), and remove the directory with that name from the current user's
# plugin directory.
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
