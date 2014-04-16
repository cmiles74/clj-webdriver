group { "puppet": ensure => "present" }

package { "unzip": ensure => present }
package { "openjdk-6-jre-headless": ensure => present }
package { "curl": ensure => present }

class chromedriver {

  $version      = '2.9'
  $basename     = "chromedriver_linux64"
  $tarball      = "${basename}.zip"
  $tarball_path = "/tmp/${tarball}"
  $url          = "http://chromedriver.storage.googleapis.com/${version}/${tarball}"
  $destdir      = "/opt/${basename}"

  package {
    'chromedriver':  ensure => absent,
  }

  exec {
    'download-chromedriver-binary':
      require => Package['curl', 'unzip'],
      command => "/usr/bin/curl -L -o ${tarball_path} ${url}",
      creates => $tarball_path;

    'unpack-chromedriver-binary':
      command => "/usr/bin/unzip ${tarball_path} -d chromedriver",
      cwd     => '/opt',
      creates => $destdir,
      require => Exec['download-chromedriver-binary'];

    'permissions-chromedriver':
      command => "/bin/chmod 775 /opt/chromedriver/chromedriver",
      require => Exec['unpack-chromedriver-binary'];
  }

  file {
    '/usr/local/bin/chromedriver':
      ensure  => link,
      target  => "/opt/chromedriver/chromedriver",
      require => Exec['unpack-chromedriver-binary'];
  }
}

class phantomjs {

  $version      = '1.9.7'
  $basename     = "phantomjs-${version}-linux-x86_64"
  $tarball      = "${basename}.tar.bz2"
  $tarball_path = "/tmp/${tarball}"
  $url          = "https://bitbucket.org/ariya/phantomjs/downloads/${tarball}"
  $destdir      = "/opt/${basename}"

  package {
    'phantomjs':  ensure => absent,
  }

  exec {
    'download-phantomjs-binary':
      require => Package['curl'],
      command => "/usr/bin/curl -L -o ${tarball_path} ${url}",
      creates => $tarball_path;

    'unpack-phantomjs-binary':
      command => "/bin/tar jxf ${tarball_path}",
      cwd     => '/opt',
      creates => $destdir,
      require => Exec['download-phantomjs-binary'];
  }

  file {
    '/usr/local/bin/phantomjs':
      ensure  => link,
      target  => "${destdir}/bin/phantomjs",
      require => Exec['unpack-phantomjs-binary'];
  }
}

class leiningen {

  $url = "https://raw.github.com/technomancy/leiningen/stable/bin/lein"

  exec {
    'download-lein':
      require => Package['curl'],
      command => "/usr/bin/curl -L -o /usr/local/bin/lein ${url}",
      creates => $tarball_path;

    'permissions-lein':
      command => "/bin/chmod 775 /usr/local/bin/lein",
      require => Exec['download-lein'];
  }
}

class selenium {

  file { "/opt/selenium":
     ensure => directory,
  }

  file { "/opt/selenium/selenium-server-standalone.jar":
     source => "/vagrant/files/opt/selenium/selenium-server-standalone-2.39.0.jar",
  }
}

class sehub {
  require selenium

  file { "/opt/selenium/sehub":
      source => "/vagrant/files/opt/selenium/sehub",
      owner => "root",
      mode => "0755",
  }

  file { "/etc/init.d/sehub":
      source => "/vagrant/files/etc/init.d/sehub",
      owner => "root",
      mode => "0755",
  }

  service { "sehub":
    require => [
        File['/etc/init.d/sehub'],
        File['/opt/selenium/sehub']
    ],
    enable => true,
    ensure => running,
  }

}

class senode {
  require selenium
  require phantomjs
  require chromedriver
  require leiningen

  package { "firefox": ensure => present }
  package { "chromium-browser": ensure => present }
  package { "vnc4server": ensure => present }

  file { "/opt/selenium/senode":
      source => "/vagrant/files/opt/selenium/senode",
      owner => "root",
      mode => "0755",
  }

  file { "/etc/init.d/senode":
      source => "/vagrant/files/etc/init.d/senode",
      owner => "root",
      mode => "0755",
  }

  user { "senode":
    managehome => true,
    ensure => present,
    gid => senode
  }

  group { "senode":
    ensure => present,
  }

  service { "senode":
    require => [
        User['senode'],
        File['/etc/init.d/senode'],
        File['/opt/selenium/senode'],
	File['/usr/local/bin/phantomjs'],
    ],
    enable => true,
    ensure => running,
  }

  file { "/etc/init.d/senodevnc":
      source => "/vagrant/files/etc/init.d/senodevnc",
      owner => "root",
      mode => "0755",
  }

  file { "/home/senode/.vnc":
    ensure => directory,
    owner => "senode",
    require => User['senode'],
  }

  file { "/home/senode/.vnc/passwd":
    source => "/vagrant/files/vnc/passwd",
    owner => "senode",
    group => "senode",
    mode => 0600,
    require => File['/home/senode/.vnc'],
  }

  file { "/home/senode/.vnc/xstartup":
    source => "/vagrant/files/vnc/xstartup",
    owner => "senode",
    mode => 0755,
    require => File['/home/senode/.vnc'],
  }

  service { "senodevnc":
    require => [
       File['/etc/init.d/senode'],
       File['/home/senode/.vnc/xstartup'],
       File['/home/senode/.vnc/passwd'],
       User['senode']
    ],
    enable => true,
    ensure => running,
  }

}
