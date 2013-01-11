#!/usr/bin/ruby
require 'yaml'
require 'fileutils'

module Enyomaton


end

# 1 Argument required - the YAML config file
if not config_file = ARGV[0]
	puts "Usage: enyomate.rb <config>"
	Process.exit
end

# Load the config
config = YAML.load_file config_file
app_name = config["app_name"]
namespace = config["namespace"]
base_dir = config["base_dir"]
gap_dir = config["phonegap_dir"]

# Move to the bootplate directory
Dir.chdir "#{base_dir}/bootplate"

# Minify the bootplate app
node_out = `node enyo/tools/deploy.js`
puts node_out

# Create the enyomaton directory, where we'll place our pg builds
if not File.directory? "#{base_dir}/bootplate/enyomaton"
	Dir.mkdir "#{base_dir}/bootplate/enyomaton"
end

# Run the phonegap create command to create the project wrapper
if not File.directory? "#{base_dir}/bootplate/enyomaton/#{app_name}"
	Dir.chdir "#{gap_dir}/lib/android/bin"
	gap_out = `./create #{base_dir}/bootplate/enyomaton/#{app_name.downcase} #{namespace}.#{app_name} #{app_name}`
	puts gap_out
end

# Move to the www directory of the Android app we just created, where our stuff needs to go
Dir.chdir "#{base_dir}/bootplate/enyomaton/#{app_name}/assets/www"

# Initialize for scope
cordova_version = nil

Dir.foreach("#{base_dir}/bootplate/enyomaton/#{app_name}/assets/www") do |item|
	#puts item #FAIL removed everything?
	if not item.match(/^\.\.?$/) and not item.match(/cordova/)
		FileUtils.rm_r item
	elsif item.match(/cordova-(.+)\.js/)
		cordova_version = "cordova-#{$1}.js"
	end
end

# Move the deploy directory and copy its contents to the phonegap wrapper
Dir.chdir "#{base_dir}/bootplate/deploy/bootplate"
FileUtils.cp_r Dir.glob("*"), "#{base_dir}/bootplate/enyomaton/#{app_name}/assets/www"

# Move the index file
Dir.chdir "#{base_dir}/bootplate/enyomaton/#{app_name}/assets/www/"
FileUtils.cp "index.html", "index.orig"

new_index = File.new "index.html", "w"

# Insert the cordova inclusion into the index file
File.open("index.orig", "r").each_line do |line|
	new_index.puts line
	if line.match(/(\s*)<!-- js -->/)
		new_index.puts "#{$1}<script src=\"#{cordova_version}\"></script>"
	end
end

new_index.close
FileUtils.rm "index.orig"