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

# def sed_append_after(vm_ref, append_string, after_string, to_filename)
#   cmd_args = [Regexp.escape(append_string), "/#{Regexp.escape(after_string)}/a #{append_string}", to_filename]
#   puts(cmd_args)
#   vm_ref.vm.provision "shell", inline: "sudo grep -q \"$1\" $3 || sed -i \"$2\" $3", args: cmd_args
# end

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

      opt.vm.network "private_network", ip: opts[:eth1]

      if false || true

        opt.vm.provision "fix-no-tty", type: "shell" do |s|
          s.privileged = false
          s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
        end

        opt.vm.provision "pg-apt", type: "shell" do |s|
          s.privileged = true
          s.path = "https://anonscm.debian.org/cgit/pkg-postgresql/postgresql-common.git/plain/pgdg/apt.postgresql.org.sh"
        end

        opt.vm.provision "shell", inline: "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postgresql-9.5"

# install packages needed to support AD SSO
#         opt.vm.provision "shell", inline: "sudo apt-get update"
        opt.vm.provision "shell", inline: "sudo echo 'krb5-config krb5-config/default_realm string #{AD_REALM}' | debconf-set-selections"
        packages = "packagekit krb5-user samba-common samba-libs samba-common-bin sssd sssd-tools realmd ntp"
        opt.vm.provision "shell", inline: "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install #{packages}"

# add hosts file entries so that DNS lookups behave
        opt.vm.provision "shell", inline: "sudo sed -i \"$1\" $2", args: ["/#{AD_DC_HOST}/d", "/etc/hosts"]
        opt.vm.provision "shell", inline: "sudo sed -i \"$1\" $2", args: ["/127\.0\.0\.1 localhost/ a #{AD_DC_IP} #{AD_DC_HOST}", "/etc/hosts"]

        # add private network for other boxes to hosts
        boxes.each do |box|
          if box[:eth1] != opts[:eth1]
            sed_cmd = "/127\.0\.0\.1 localhost/a #{box[:eth1]} #{box[:hostname]} #{box[:hostname]}.#{AD_DOMAIN}"
            opt.vm.provision "shell", inline: "sudo grep -q '^#{box[:eth1]} #{box[:hostname]}' /etc/hosts || sed -i \"$1\" $2", args: [sed_cmd, "/etc/hosts"]
          end
        end

# link up NTP to the DC so we don't have time skew
        opt.vm.provision "shell", inline: "sudo service ntp stop"
        opt.vm.provision "shell", inline: "sudo sed -i \"$1\" $2", args: ["/server #{AD_DC_HOST}/d", "/etc/ntp.conf"]
        opt.vm.provision "shell", inline: "sudo sed -i \"$1\" $2", args: ["s/^server/# server/", "/etc/ntp.conf"]
        opt.vm.provision "shell", inline: "sudo sed -i \"$1\" $2", args: ["/server ntp\.ubuntu\.com/ a server #{AD_DC_HOST}", "/etc/ntp.conf"]
        opt.vm.provision "shell", inline: "sudo ntpdate #{AD_DC_HOST}"
        opt.vm.provision "shell", inline: "sudo service ntp start"

# add additional entries into krb5.conf file
        sed_cmd = "/[[]libdefaults[]]/a default_ccache_name = KEYRING:persistent:%{uid}"
        opt.vm.provision "shell", inline: "sudo grep -q 'default_ccache_name = ' /etc/krb5.conf || sed -i \"$1\" $2", args: [sed_cmd, "/etc/krb5.conf"]

        sed_cmd = "/[[]libdefaults[]]/a rdns = false"
        opt.vm.provision "shell", inline: "sudo grep -q 'rdns = ' /etc/krb5.conf || sed -i \"$1\" $2", args: [sed_cmd, "/etc/krb5.conf"]

        sed_cmd = "/[[]libdefaults[]]/a renew_lifetime = 7d"
        opt.vm.provision "shell", inline: "sudo grep -q 'renew_lifetime = ' /etc/krb5.conf || sed -i \"$1\" $2", args: [sed_cmd, "/etc/krb5.conf"]

        sed_cmd = "/[[]libdefaults[]]/a ticket_lifetime = 24h"
        opt.vm.provision "shell", inline: "sudo grep -q 'ticket_lifetime = ' /etc/krb5.conf || sed -i \"$1\" $2", args: [sed_cmd, "/etc/krb5.conf"]

        sed_cmd = "/[[]libdefaults[]]/a dns_lookup_realm = false"
        opt.vm.provision "shell", inline: "sudo grep -q 'dns_lookup_realm = ' /etc/krb5.conf || sed -i \"$1\" $2", args: [sed_cmd, "/etc/krb5.conf"]

# create the realmd.conf file
        opt.vm.provision "file", source: "./realmd.conf", destination: "./realmd.conf"
        opt.vm.provision "shell", inline: "sudo cp ./realmd.conf /etc/realmd.conf"

# add pam config to auto-create home directory on login
        sed_cmd = "/session	required	pam_unix.so/a session    required    pam_mkhomedir.so skel=/etc/skel/ umask=0022"
        opt.vm.provision "shell", inline: "sudo grep -q 'session    required    pam_mkhomedir' /etc/krb5.conf || sed -i \"$1\" $2", args: [sed_cmd, "/etc/pam.d/common-session"]

# sed -i "s/GSSAPIDelegateCredentials no/GSSAPIDelegateCredentials yes/" /etc/ssh/ssh_config

# join domain. leave first to allow rejoin without error, ignore any error from the leave
        opt.vm.provision "shell", inline: "sudo sh -c 'realm --verbose leave ; true'"
        opt.vm.provision "shell", inline: "sudo realm --verbose --user=#{AD_ADMIN} join #{AD_DOMAIN} <<<'#{AD_PASS}'"

        opt.vm.provision "shell", inline: "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install ssh-krb5"
        opt.vm.provision "shell", inline: "sudo realm permit --groups 'Domain Admins'"
        opt.vm.provision "shell", inline: "sudo service sssd restart"

      end

      # Add config file entries to
      opt.vm.provision 'shell', inline: 'sudo sed -i "s/#listen_addresses = ' \
               '\'localhost\'/listen_addresses = \'*\'/" ' \
               '/etc/postgresql/9.5/main/postgresql.conf'
      opt.vm.provision 'shell', inline: 'grep -q krb_server_keyfile ' \
               '/etc/postgresql/9.5/main/postgresql.conf || ' \
               'echo -e "\n# support AD auth\nkrb_server_keyfile = ' \
               '\'/etc/postgresql/9.5/main/postgres.keytab\'" >> ' \
               '/etc/postgresql/9.5/main/postgresql.conf'

      opt.vm.provision 'shell', inline: 'grep -q "host.*gss" ' \
               '/etc/postgresql/9.5/main/pg_hba.conf || ' \
               'echo -e "\n# support AD auth\n' \
               "host    all       all     0.0.0.0/0    gss include_realm=1 krb_realm=#{AD_REALM}\" >> " \
               '/etc/postgresql/9.5/main/pg_hba.conf'

      opt.vm.provision 'file', source: './postgres.keytab', destination: './postgres.keytab'
      opt.vm.provision 'shell', inline: 'sudo cp ./postgres.keytab /etc/postgresql/9.5/main/postgres.keytab'
      opt.vm.provision 'shell', inline: 'sudo chown postgres:postgres /etc/postgresql/9.5/main/postgres.keytab'

      opt.vm.provision "shell", inline: "sudo service postgresql restart"

      # configure OpenSSH
      # default domain & don't use FQDN
      # domain admins to sudoers
    end
  end
end

