# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hiera_ssm_paramstore::config
class hiera_ssm_paramstore::config {

  $config_dir = $hiera_ssm_paramstore::config_dir ? {
    undef   => $hiera_ssm_paramstore::user ? {
      'puppet' => "${::puppet_vardir}/.aws",
      'root'   => "${::root_home}/.aws",
      default  => "/home/${hiera_ssm_paramstore::user}/.aws",
    },
    default => $hiera_ssm_paramstore::config_dir,
  }

  file { $config_dir:
    ensure => directory
    owner  => $user,
    group  => $user,
    mode   => '0700',
  } ->

  Ini_setting{
    ensure => present
    path   => $config_dir,
  }

  file { "${config_dir}/config":
    ensure => file,
    owner  => $user,
    group  => $user,
    mode   => '0600',
  } ->

  file { "${config_dir}/credentials":
    ensure => file,
    owner  => $user,
    group  => $user,
    mode   => '0600',
  } ->

}
