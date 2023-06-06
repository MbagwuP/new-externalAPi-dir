#
# Cookbook Name:: app_external
# Recipe:: deploy
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

appns = node['ccbase']['application']

if node[appns]['deploy_type'] == "git"
    include_recipe "app_external::_deploy_git"
elsif node[appns]['deploy_type'] == "artifact"
    include_recipe "app_external::_deploy_artifact"
else
    raise "Deploy strategy is not supported"
end
