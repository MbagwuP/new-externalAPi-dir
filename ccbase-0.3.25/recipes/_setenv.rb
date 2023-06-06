#
# Cookbook Name:: ccbase
# Recipe:: _setenv
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

ruby_block "Set environmental variables" do
  block do
    envsh = "/etc/profile.d/environment.sh"
    unless ::File.exists?(envsh)
      cmd = Mixlib::ShellOut.new("touch #{envsh}", user: "root") 
      cmd.run_command 
    end

    # This logic will collect all items in the data bags with the following pattern: (<appname>-envars-<environment>)
    # and convert them to system environmental variables.
    begin
      data_bag_key, envars = "#{node['ccbase']['application']}-envars-#{node.chef_environment}", {}
      unless node['virtualization']['system'] == "docker"
        data_bag(data_bag_key).each do |bag|
          envars.merge!(data_bag_item(data_bag_key, bag).to_hash['envs'])
        end
      end
    rescue Net::HTTPServerException => e
      Chef::Log.debug("Optional centralized environment databag (#{data_bag_key}) not detected.")
      Chef::Log.debug(e.message)
    end

    # This will override or set node specific environmental variables.
    envars.merge!(node['ccbase']['envs'])

    # Make application envars usable in the node run.
    node.default['ccbase']['context']['envs'] = envars

    envars.each_pair do |key, value|
      file = Chef::Util::FileEdit.new(envsh)
      variable = key.upcase
      file.search_file_replace_line(/^export #{variable}=/m, "export #{variable}=\"#{value}\"")
      file.insert_line_if_no_match(/^export #{variable}=/m, "export #{variable}=\"#{value}\"")
      file.write_file
    end
  end
  action :run
end.run_action(:run)
