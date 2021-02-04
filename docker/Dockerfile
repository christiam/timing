FROM christiam/blast:2.10.1 as blast
ARG version
LABEL Description="NCBI BLAST" Vendor="NCBI/NLM/NIH" Version=${version} Maintainer=camacho@ncbi.nlm.nih.gov

FROM google/cloud-sdk:slim

USER root
WORKDIR /root/

RUN apt-get -y -m update && apt-get install -y libgomp1 libnet-perl libidn11 libxml-simple-perl libjson-perl perl-doc liblmdb-dev time parallel vmtouch cpanminus curl wget libio-socket-ssl-perl libhtml-parser-perl lsof pstack && \
	rm -rf /var/lib/apt/lists/*  

#RUN echo 'will cite' | parallel --citation
RUN mkdir /root/.parallel
RUN touch /root/.parallel/will-cite


RUN mkdir -p /blast/bin /blast/lib
COPY --from=blast /blast/bin /blast/bin
COPY --from=blast /blast/lib /blast/lib
COPY --from=blast /root/edirect /root/edirect
COPY download-blastdb.py update_blastdb.pl /blast/bin/

RUN mkdir -p /blast/blastdb /blast/blastdb_custom
RUN sed -i '$ a BLASTDB=/blast/blastdb:/blast/blastdb_custom' /etc/environment
ENV BLASTDB /blast/blastdb:/blast/blastdb_custom
ENV PATH="/root/edirect:/blast/bin:${PATH}"


WORKDIR /blast

CMD ["/bin/bash"]

