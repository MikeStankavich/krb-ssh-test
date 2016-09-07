#!/usr/bin/env bash
DEBIAN_FRONTEND=noninteractive
apt-get -y install postgresql-9.5

# Add config file entries
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/9.5/main/postgresql.conf
grep -q krb_server_keyfile /etc/postgresql/9.5/main/postgresql.conf || echo -e "\n# support AD auth\nkrb_server_keyfile = '/etc/postgresql/9.5/main/postgres.keytab'" >> /etc/postgresql/9.5/main/postgresql.conf
grep -q "host.*gss" /etc/postgresql/9.5/main/pg_hba.conf || echo -e "\n# support AD auth\n host    all       all     0.0.0.0/0    gss" >> /etc/postgresql/9.5/main/pg_hba.conf

cp ./postgres.keytab /etc/postgresql/9.5/main/postgres.keytab
chown postgres:postgres /etc/postgresql/9.5/main/postgres.keytab

service postgresql restart
