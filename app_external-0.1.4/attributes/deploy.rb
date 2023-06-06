appns         = node['ccbase']['application'] # Application Namespace
deploy_config = Chef::DataBagItem.load(appns, 'app_version')[chef_environment]

default[appns]['deploy_type']         = deploy_config['type']        || "git"
default[appns]['deploy_revision']     = deploy_config['revision']    || "master"
default[appns]['deploy_release_type'] = deploy_config['release_type'] || "pre-release"
default[appns]['deploy_user']         = "deploy"
default[appns]['deploy_group']        = "deploy"

default[appns]['shared_dirs']     = %w{config vendor_bundle log tmp/pids db}
default[appns]['configs_databag'] = "#{appns}-configs-#{chef_environment}"
default[appns]['configs']         = (node['ccbase']['config_ctxt_environment'] ? [] : Chef::DataBag.load(default[appns]['configs_databag']).keys) rescue []

default[appns]['symlinks'] = Hash[*default[appns]['configs'].map { |config| ["config/#{config}.yml","config/#{config}.yml"] }.flatten]
default[appns]['symlinks'] = default[appns]['symlinks'].tap do |symlink|
  symlink['log']           = "log"
  symlink['tmp']           = "tmp"
  symlink['vendor_bundle'] = "vendor/bundle" if node['ccbase']['bundle']
end

default[appns]['purge_files_before_symlink'] = default[appns]['symlinks'].values
