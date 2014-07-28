class postgresql::server (
  $server_package = $postgresql::params::server_package,
  $locale = $postgresql::params::locale,
  $version = $postgresql::params::version,
  $listen = $postgresql::params::listen_address,
  $port = $postgresql::params::port,
  $ssl = $postgresql::params::ssl,
  $ssl_ca_file   = $postgresql::params::ssl_ca_file,
  $ssl_cert_file = $postgresql::params::ssl_cert_file,
  $ssl_crl_file  = $postgresql::params::ssl_crl_file,
  $ssl_key_file  = $postgresql::params::ssl_key_file,
  $preacl = [],
  $acl = [],
  $manage_service = true,
  $log_autovacuum_min_duration = -1,
  $max_connections = 100,
  $shared_buffers = '24MB',
  $effective_cache_size = '128MB',
  $work_mem = '1MB',
  $maintenance_work_mem = '32MB',
  $checkpoint_segments = 32,
  $checkpoint_completion_target = 0.7,
  $wal_buffers = '1MB',
  $default_statistics_target = 100,
  $shmmax=536870912,
  $shmall=131072,
) inherits postgresql::params {

  file { 'postgresql-server-policyrc.d':
    ensure => present,
    name   => '/usr/sbin/policy-rc.d',
    owner  => root,
    group  => root,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/postgresql-policyrc.d"
  }

  if ($manage_service) {

    service { "postgresql-system-$version":
      name        => 'postgresql',
      enable      => true,
      ensure      => running,
      hasstatus   => false,
      hasrestart  => true,
      provider    => 'debian',
      subscribe   => Package["postgresql-server-$version"],
    }

    $notify_service = Service["postgresql-system-$version"]
    $package_require = []

  } else {

    $notify_service = []
    $package_require = File['postgresql-server-policyrc.d']

  }

  package { "postgresql-server-$version":
    name    => sprintf("%s-%s", $server_package, $version),
    ensure  => present,
    require => $package_require,
  }

  file { "postgresql-server-config-$version":
    name    => "/etc/postgresql/$version/main/postgresql.conf",
    ensure  => present,
    content => template('postgresql/postgresql.conf.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0644',
    require => Package["postgresql-server-$version"],
    notify  => $notify_service,
  }

  file { "postgresql-server-hba-config-$version":
    name    => "/etc/postgresql/$version/main/pg_hba.conf",
    ensure  => present,
    content => template('postgresql/pg_hba.conf.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0640',
    require => Package["postgresql-server-$version"],
    notify  => $notify_service,
  }

  file { "postgresql-sysctl":
    name    => "/etc/sysctl.d/30-postgresql-shm.conf",
    ensure  => present,
    content => template('postgresql/30-postgresql-shm.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
  }
}
