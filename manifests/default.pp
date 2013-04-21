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

    exec { 'PHPMyAdmin webserver':
        command => "echo phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2 | debconf-set-selections"
    }

    exec { 'PHPMyAdmin dbconfig':
        command => "echo phpmyadmin phpmyadmin/dbconfig-install boolean false | debconf-set-selections"
    }
}

class packages {
    exec { 'Update repositories':
        command => 'apt-get update'
    }

    notify { 'LAMP server':
        message => 'Installing packages. This may take a while.'
        , before => Exec['Install LAMP server']
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

    package { 'Install PHPMyAdmin':
        name => 'phpmyadmin'
        , require => Exec['Install LAMP server']

    }
}

service { 'apache2':
    ensure => running
    , enable => true
}

service { 'mysql':
    ensure => running
    , enable => true
}

class setup {
    exec { 'Add mysql user cs160@%':
        command => "mysql -u root -p${MySQL_password} -e \"CREATE USER 'cs160'@'%' IDENTIFIED BY 'cs160_password'\""
        , require => Service['mysql']
    }

    exec { 'Add mysql user cs160@localhost':
        command => "mysql -u root -p${MySQL_password} -e \"CREATE USER 'cs160'@'localhost' IDENTIFIED BY 'cs160_password'\""
        , require => Service['mysql']
    }

    exec { 'Add mysql database cs160':
        command => "mysql -u root -p${MySQL_password} -e \"CREATE DATABASE IF NOT EXISTS cs160\""
        , require => Exec['Add mysql user cs160@%']
    }

    exec { 'Grant mysql database cs160 to user cs160':
        command => "mysql -u root -p${MySQL_password} -e \"GRANT ALL ON cs160.* TO 'cs160'@'%'\""
        , require => Exec['Add mysql database cs160']
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
        , notify => Service['apache2']
    }

    file { 'Add link to site files':
    	path => '/home/vagrant/public_html'
    	, ensure => link
    	, target => '/vagrant/moocs'
    }

    file { 'Add MySQL configuration':
        path => '/etc/mysql/my.cnf'
        , ensure => present
        , source => '/vagrant/assets/cs160.my.conf'
        , notify => Service['mysql']
    }
}

class { 'debconf': }

class { 'packages':
    require => Class['debconf']
}

class { 'setup':
    require => Class['packages']
}

