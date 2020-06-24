# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hiera_ssm_paramstore
class hiera_ssm_paramstore (
  String               $access_key        = undef,
  Stdlib::Absolutepath $config_dir,
  String               $package_name      = undef,
  String               $region            = undef,
  String               $role_arn          = undef,
  String               $secret_access_key = undef,
  String               $user              = undef,
){

  contain '::hiera_ssm_paramstore::config'
  contain '::hiera_ssm_paramstore::install'

}
