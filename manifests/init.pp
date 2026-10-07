# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# Package containing the hiera_ssm_paramstore dependencies.
#
# @param package_name
#   Name of the package to install.
#
# @example
#   include hiera_ssm_paramstore
class hiera_ssm_paramstore (
  String $package_name,
) {
  $provider = $facts['environment'] ? {
    'vagrant' => puppet_gem,
    default   => puppetserver_gem,
  }

  package { $package_name:
    ensure   => present,
    provider => $provider,
  }
}
