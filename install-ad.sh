apt-get update
echo "krb5-config krb5-config/default_realm string JAXPK.COM" | debconf-set-selections
apt-get -y install realmd sssd sssd-tools samba-common krb5-user packagekit samba-common-bin samba-libs
cp /etc/krb5.conf ./
sed '/\[libdefaults\]/ r ./krb5.conf.add' ./krb5.conf > /etc/krb5.conf
cp ./realmd.conf /etc/
realm --verbose --user=administrator@jaxpk.com join jaxpk.com
