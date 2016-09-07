#!/usr/bin/env bash
# $1: AD Realm
# $2: AD DC IP
# $3: AD DC host fqdn
# $4: AD Domain
# $5: AD admin user
# $6: AD admin password

echo "krb5-config krb5-config/default_realm string $1" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive
apt-get -y install packagekit krb5-user samba-common samba-libs samba-common-bin sssd sssd-tools realmd

# add hosts file entries so that DNS lookups behave
#sed -i "/$2 $3/d" /etc/hosts
#sed -i "/127\.0\.0\.1 localhost/a $2 $3" /etc/hosts

grep -q 'default_ccache_name = ' /etc/krb5.conf || sed -i "/[[]libdefaults[]]/a default_ccache_name = KEYRING:persistent:%{uid}" /etc/krb5.conf
grep -q 'rdns = false' /etc/krb5.conf || sed -i "/[[]libdefaults[]]/a rdns = false" /etc/krb5.conf
grep -q 'renew_lifetime = ' /etc/krb5.conf || sed -i "/[[]libdefaults[]]/a renew_lifetime = 7d" /etc/krb5.conf
grep -q 'ticket_lifetime = ' /etc/krb5.conf || sed -i "/[[]libdefaults[]]/a ticket_lifetime = 24h" /etc/krb5.conf
grep -q 'dns_lookup_realm = ' /etc/krb5.conf || sed -i "/[[]libdefaults[]]/a dns_lookup_realm = false" /etc/krb5.conf

grep -q 'session    required    pam_mkhomedir' /etc/krb5.conf || sed -i "/session	required	pam_unix.so/a session    required    pam_mkhomedir.so skel=/etc/skel/ umask=0022" /etc/pam.d/common-session

cp ./realmd.conf /etc/realmd.conf

realm --verbose leave ; true
realm --verbose --user=$5 join $4 <<<"$6"
realm permit --groups 'Domain Admins'
service sssd restart
