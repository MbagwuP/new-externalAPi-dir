appns = node['ccbase']['application']
software_pkg = "#{node[appns]['deploy_revision']}.tar.gz"

ccbase_artifact_deploy appns do
  artifact_location ::File.join('s3://s3.amazonaws.com', 'cc-ci-drop', appns, node[appns]['deploy_release_type'], software_pkg)
  version software_pkg.split('.')[0]
  shared_directories node[appns]['shared_dirs'] 

  # Symlink app configs from the shared directory to the 
  # current release configs directory.
  symlinks node[appns]['symlinks']
end
