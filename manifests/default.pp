Exec {
    path => [
        '/usr/local/sbin'
        , '/usr/local/bin'
        , '/usr/sbin'
        , '/usr/bin'
        , '/sbin'
        , '/bin'
    ]
}

$MySQL_password = 'ChangeThisInsecurePassword'

class debconf {
    exec { 'MySQL_root_PW':
        command => "echo mysql-server-5.5 mysql-server/root_password select ${MySQL_password} | debconf-set-selections"
    }

    exec { 'MySQL_root_PW_confirm':
        command => "echo mysql-server-5.5 mysql-server/root_password_again select ${MySQL_password} | debconf-set-selections"
    }
}

class services {
    exec { 'Update repositories':
        command => 'apt-get update'
    }

    exec { 'Install LAMP server':
        command => 'tasksel install lamp-server'
        , require => [
            Exec['Update repositories']
        ]
    }

    package { 'Install MySQL Client':
        name => 'mysql-client-5.5'
        , require => Exec['Update repositories']
    }

    service { 'mysql':
        ensure => running
        , enable => true
        , require => Exec['Install LAMP server']
    }
}

class setup {
    exec { 'Add CS 160 user':
        command => "mysql -u root -p${MySQL_password} -e \"CREATE USER 'cs160'@'localhost' IDENTIFIED BY 'cs160_password'\""
    }

    exec { 'Add CS 160 database':
        command => "mysql -u root -p${MySQL_password} -e \"CREATE DATABASE IF NOT EXISTS cs160\""
        , require => Exec['Add CS 160 user']
    }

    exec { 'Add CS 160 permissions':
        command => "mysql -u root -p${MySQL_password} -e \"GRANT ALL ON cs160.* TO cs160\""
        , require => Exec['Add CS 160 database']
    }

    file { 'Disable default virtualhost':
    	path => '/etc/apache2/sites-enabled/000-default'
    	, ensure => absent
    }

    file { 'Add CS 160 virtualhost file':
    	path => '/etc/apache2/sites-available/cs160'
    	, ensure => present
    	, source => '/vagrant/assets/cs160.virtualhost'
    }

    file { 'Add link to cs160 virtualhost':
        path => '/etc/apache2/sites-enabled/cs160'
        , ensure => link
        , target => '/etc/apache2/sites-available/cs160'
        , require => File['Add CS 160 virtualhost file']
    }

    file { 'Add link to site files':
    	path => '/home/vagrant/public_html'
    	, ensure => link
    	, target => '/vagrant/moocs'
    }
}

class restart {
    exec { 'Reload Apache':
        command => 'apache2ctl restart'
    }
}

class { 'debconf': }

class { 'services':
    require => Class['debconf']
}

class { 'setup':
    require => Class['services']
}

class { 'restart':
    require => Class['setup']
}