FROM ubuntu:trusty

RUN apt-get update && apt-get install -y -q curl bzip2 wget build-essential git && \
 curl https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
 /bin/bash /tmp/miniconda.sh -b -p /opt/conda && \
 rm /tmp/miniconda.sh
ENV PATH /opt/conda/bin:$PATH

RUN conda install -y -q ipython pytest openjdk maven conda-build anaconda-client && \
 conda install -y -q hdfs3 s3fs gcsfs -c conda-forge

# EXPOSE 8888
# ENV TINI_VERSION v0.9.0
# ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
# ENTRYPOINT ["/usr/bin/tini", "--"]
