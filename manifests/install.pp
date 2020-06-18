# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hiera_ssm_paramstore::install
class hiera_ssm_paramstore::install {

  $provider = $::environment ? {
    'vagrant' => puppet_gem,
    default   => puppetserver_gem,
  }

  package { $hiera_ssm_paramstore::package_name:
    ensure   => present,
    provider => $provider,
  }

}
