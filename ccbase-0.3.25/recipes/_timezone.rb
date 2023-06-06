#
# Cookbook Name:: ccbase
# Recipe:: _timezone
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# NOTE: Run is based on default[:tz] in attributes directory default.rb
include_recipe "timezone-ii::default"
