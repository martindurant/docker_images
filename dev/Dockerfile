FROM ubuntu:trusty

RUN apt-get update && apt-get install -y -q curl bzip2 wget build-essential git ssh rsync nano openssh-server && \
 apt-get clean && \
 curl https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
 /bin/bash /tmp/miniconda.sh -b -p /opt/conda && \
 rm /tmp/miniconda.sh
ENV PATH /opt/conda/bin:$PATH
ENV JAVA_HOME /opt/conda

RUN conda install -y -q ipython pytest openjdk maven conda-build anaconda-client && \
 conda install -y -q hdfs3 s3fs gcsfs -c conda-forge

EXPOSE 22

ENV TINI_VERSION v0.15.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["bash"]