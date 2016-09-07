# -*- mod: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
AD_REALM = "JAXPK.COM"
AD_DOMAIN = "jaxpk.com"
AD_ADMIN = "Administrator@#{AD_DOMAIN}"
AD_PASS = "scmd3M()"
AD_DC_IP = "54.82.246.87"
AD_DC_HOST = "scm-demo-dc.jaxpk.com"

ad = {
    :realm => "JAXPK.COM" ,
    :domain => "jaxpk.com",
    :admin => "administrator@jaxpk.com",
    :dc_ip => "54.82.246.87",
    :dc_host => "scm-demo-dc.jaxpk.com"
}

boxes = [
    {
        :name => "sso1",
        :hostname => "ssotest1",
        :eth1 => "192.168.205.10",
        :mem => "512",
        :cpu => "2"
    },
    {
        :name => "sso2",
        :hostname => "ssotest2",
        :eth1 => "192.168.205.11",
        :mem => "512",
        :cpu => "2"
    }
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/trusty64"

  boxes.each do |opts|

    config.vm.define opts[:name] do |opt|

      opt.vm.hostname = "#{opts[:hostname]}.#{AD_DOMAIN}"
      opt.vm.provider :virtualbox do |v|
        v.name = opts[:name]
        v.memory = opts[:mem]
        v.cpus = opts[:cpu]
        v.customize ["modifyvm", :id, "--ioapic", "on"]
      end

      opt.vm.provision "fix-no-tty", type: "shell" do |s|
        s.privileged = true
        s.inline = "sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
      end

      opt.vm.network "private_network", ip: opts[:eth1]

      # add private network for other boxes to hosts
      boxes.each do |box|
        if box[:eth1] != opts[:eth1]
          opt.vm.provision 'shell' do |s|
            s.inline = "sudo grep -q '^#{box[:eth1]} #{box[:hostname]}' /etc/hosts || sed -i \"$1\" $2"
            s.args = ["/127\.0\.0\.1 localhost/a #{box[:eth1]} #{box[:hostname]} #{box[:hostname]}.#{AD_DOMAIN}"]
            s.args << "/etc/hosts"
          end
        end
      end

      opt.vm.provision 'shell', privileged: true, inline: "apt-get update"

      # create the realmd.conf file
      opt.vm.provision 'file', source: './realmd.conf', destination: './realmd.conf'
      opt.vm.provision 'shell', privileged: true, path: "./ntp-install.sh", args: [AD_DC_HOST]
      opt.vm.provision 'shell' do |s|
        s.privileged = true
        s.path = './realm-install.sh'
        s.args = [AD_REALM, AD_DC_IP, AD_DC_HOST, AD_DOMAIN, AD_ADMIN, AD_PASS]
      end
      # domain admins to sudoers ???

      # enable kerberos for ssh
      opt.vm.provision 'shell', inline: "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install ssh-krb5"

      # opt.vm.provision 'file', source: './postgres.keytab', destination: './postgres.keytab'
      # opt.vm.provision 'shell', privileged: true, path: "./apt.postgresql.org.sh"
      # opt.vm.provision 'shell', privileged: true, path: "./postgres-install.sh"

    end
  end
end
