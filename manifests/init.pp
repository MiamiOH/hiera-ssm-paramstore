# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hiera_ssm_paramstore
class hiera_ssm_paramstore (
  $access_key        = undef,
  $config_dir        = undef,
  $region            = undef,
  $role_arn          = undef,
  $secret_access_key = undef,
  $user              = undef,
){

  $provider = $::environment ? {
    'vagrant' => puppet_gem,
    default   => puppetserver_gem,
  }

  package { 'aws-sdk-ssm':
    ensure   => present,
    provider => $provider,
  }

  $_config_dir = $config_dir ? {
    undef   => $user ? {
      'puppet' => "${::puppet_vardir}/.aws",
      'root'   => "${::root_home}/.aws",
      default  => "/home/${user}/.aws",
    },
    default => $config_dir,
  }

  hiera_ssm_paramstore::config {
    access_key        => $access_key,
    config_dir        => $_config_dir,
    region            => $region,
    role_arn          => $role_arn,
    secret_access_key => $secret_access_key,
    before            => Package['aws-sdk-ssm'],
  }
}
