FROM mdurant/hadoop

# input from https://github.com/tillt/docker-kdc
ADD *.xml $HADOOP_HOME/etc/hadoop/
ADD run.sh /opt/hadoop/run.sh
ARG DEBIAN_FRONTEND=noninteractive
ADD debconf debconf

RUN apt-get update && debconf-set-selections debconf && apt-get install krb5-admin-server -y && apt-get install krb5-kdc -y

EXPOSE	88

# Create keytab folder.
RUN mkdir /etc/docker-kdc && mkdir /var/log/kerberos/

#RUN kadmin.local addprinc default/admin@LOCAL-DEV.EXAMPLE.COM
#RUN kadmin.local ext_keytab -k /etc/docker-kdc/krb5.keytab
