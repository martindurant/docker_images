FROM mdurant/docker_images:dev

ENV HADOOP_VERSION 2.8.1
ENV HADOOP_HOME /opt/hadoop
RUN wget -q http://apache.mirror.rafal.ca/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
 tar xzf hadoop-$HADOOP_VERSION.tar.gz && \
 mv hadoop-$HADOOP_VERSION /opt/hadoop && \
 rm hadoop-$HADOOP_VERSION.tar.gz && \
 service ssh start

ADD *.xml $HADOOP_HOME/etc/hadoop/
ADD run.sh .

EXPOSE 50070 8020

ENV PATH $HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
RUN hdfs namenode -format
# make non-privilaged user?

ENTRYPOINT ["run.sh"]