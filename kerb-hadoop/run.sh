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
exit 1' > cmd
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
exit 1' > cmd2
expect cmd2
mv *keytab /opt/hadoop/etc/hadoop

service ssh restart
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts
echo 'export JAVA_HOME='$JAVA_HOME | cat - /opt/hadoop/etc/hadoop/hadoop-env.sh > temp
rm /opt/hadoop/etc/hadoop/hadoop-env.sh 
mv temp /opt/hadoop/etc/hadoop/hadoop-env.sh
chmod 0600 ~/.ssh/authorized_keys
start-dfs.sh
start-yarn.sh
hdfs dfs -mkdir /tmp
hdfs dfs -chmod 777 /tmp


while :
do
    sleep 1
done
