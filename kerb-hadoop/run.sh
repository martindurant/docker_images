#!/bin/bash

trap "echo exit;exit 0" SIGINT

apt-get install expect -y

echo "*/admin *" >> /etc/krb5kdc/kadm5.acl
yes CONTINUUM | krb5_newrealm
echo '
spawn kadmin.local
expect "kadmin.local:"
send "ank admin/admin\r"
expect "Enter password for principal"
send "CONTINUUM\r"
expect "Re-enter password for principal"
send "CONTINUUM\r"
expect "kadmin.local:"
exit 0' > cmd
expect cmd
yes CONTINUUM | kinit admin/admin
yes CONTINUUM | kadmin addprinc -pw CONTINUUM hdfs/kerb
yes CONTINUUM | kadmin addprinc -pw CONTINUUM yarn/kerb
yes CONTINUUM | kadmin addprinc -pw CONTINUUM http/kerb
yes CONTINUUM | kadmin addprinc -pw CONTINUUM user
yes CONTINUUM | kadmin xst -k hdfs-unmerged.keytab hdfs/kerb
yes CONTINUUM | kadmin xst -k yarn-unmerged.keytab yarn/kerb
yes CONTINUUM | kadmin xst -k http.keytab http/kerb
echo '
spawn ktutil
expect "ktutil"
send "rkt hdfs-unmerged.keytab\r"
expect "ktutil"
send "rkt http.keytab\r"
expect "ktutil"
send "wkt hdfs.keytab\r"
expect "ktutil"
send "clear\r"
expect "ktutil"
send "rkt yarn-unmerged.keytab\r"
expect "ktutil"
send "rkt http.keytab\r"
expect "ktutil"
send "wkt yarn.keytab\r"
exit 0' > cmd2
expect cmd2
mv *keytab /opt/hadoop/etc/hadoop

#Step 1
keytool -keystore server.keystore.jks -alias localhost -validity 365 -genkey -storepass keytool -keypass keytool -dname 'CN=AA, OU=AA, O=AA, L=AA, ST=AA, C=AA'

#Step 2
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 -nodes -subj '/CN=AA/OU=AA/O=AA/L=AA/ST=AA/C=AA'
echo '
spawn keytool -keystore server.truststore.jks -alias CARoot -import -file ca-cert
expect "password:"
send "keytool\r"
expect "password:"
send "keytool\r"
expect "Trust this certificate?"
send "yes\r"
exit 0' > cmd3
expect cmd3
echo '
spawn keytool -keystore client.truststore.jks -alias CARoot -import -file ca-cert
expect "password:"
send "keytool\r"
expect "password:"
send "keytool\r"
expect "Trust this certificate?"
send "yes\r"
exit 0' > cmd4

#Step 3 
keytool -keystore server.keystore.jks -alias localhost -certreq -file cert-file
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:keytool
keytool -keystore server.keystore.jks -alias CARoot -import -file ca-cert
keytool -keystore server.keystore.jks -alias localhost -import -file cert-signed

mkdir -m 0700 /root/CA /root/CA/certs /root/CA/crl /root/CA/newcerts /root/CA/private
mv ca.key /root/CA/private;mv ca.crt /root/CA/certs
touch /root/CA/index.txt; echo 1000 >> /root/CA/serial 
chmod 0400 /root/ca/private/ca.key
rm /etc/pki/tls/openssl.cnf

echo '[ CA_default ]

dir             = /root/CA                  # Where everything is kept
certs           = /root/CA/certs            # Where the issued certs are kept
crl_dir         = /root/CA/crl              # Where the issued crl are kept
database        = /root/CA/index.txt        # database index file.
#unique_subject = no                        # Set to 'no' to allow creation of
                                            # several certificates with same subject.
new_certs_dir   = /root/CA/newcerts         # default place for new certs.

certificate     = /root/CA/cacert.pem       # The CA certificate
serial          = /root/CA/serial           # The current serial number
crlnumber       = /root/CA/crlnumber        # the current crl number
                                            # must be commented out to leave a V1 CRL
crl             = $dir/crl.pem               # The current CRL
private_key     = /root/CA/private/cakey.pem # The private key
RANDFILE        = /root/CA/private/.rand     # private random number file

x509_extensions = usr_cert              # The extensions to add to the cert' > /etc/pki/tls/openssl.cnf

service ssh restart
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts
echo 'export JAVA_HOME='$JAVA_HOME | cat - /opt/hadoop/etc/hadoop/hadoop-env.sh > temp
rm /opt/hadoop/etc/hadoop/hadoop-env.sh 
mv temp /opt/hadoop/etc/hadoop/hadoop-env.sh
chmod 0600 ~/.ssh/authorized_keys

start-yarn.sh
hdfs dfs -mkdir /tmp
hdfs dfs -chmod 777 /tmp


while :
do
    sleep 1
done
