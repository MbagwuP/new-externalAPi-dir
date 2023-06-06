appns = node['ccbase']['application']

ccbase_git_deploy appns do
  branch node[appns]['deploy_revision']
  deploy_key_source "app_external"

  # Symlink app configs from the shared directory to the
  # current release configs directory.
  symlinks node[appns]['symlinks']
end
