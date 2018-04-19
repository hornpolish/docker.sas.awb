FROM centos:7
#
# see https://hub.docker.com/_/centos/
# these entries from "Dockerfile for systemd base image" Section
#
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;\
yum -y install yum-plugin-ovl 

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]

MAINTAINER Paul Kent "paul.kent@sas.com"

ENV anaVERSION="3-5.1.0" \
    swatRELEASE="https://github.com/sassoftware/python-swat/releases" \
    swatVERSION="1.3.0"

# users
# TODO -- use real users
RUN groupadd -g 1001 sas; \
    useradd -u 1001 -g sas sas; \
    useradd -u 1002 -g sas cas; \
    useradd -u 1003 -g sas sasdemo; \
    sh -c 'echo "sasSAS" | passwd "sas" --stdin'; \
    sh -c 'echo "sasCAS" | passwd "cas" --stdin'; \
    sh -c 'echo "sasDEMO" | passwd "sasdemo" --stdin'


# install pre-reqs
# dont need these anymore: xterm epel-release ansible 
RUN rpmdb --rebuilddb; \
    yum -y install java-1.8.0-openjdk openssh-clients openssh-server glibc \
                   libpng12 libXp libXmu net-tools numactl sudo            \
                   httpd mod_ssl                                           \
                   which initscripts iproute lsof git wget bzip2;          \
    yum clean all

# get systemd going
RUN systemctl enable systemd-user-sessions

# prerequisites
RUN sed -i "/keepcache=/c\keepcache=1" /etc/yum.conf; \
    sh -c 'echo "*     -     nofile     20480" >> /etc/security/limits.conf'; \
    sed -i.bak -e 's/4096/65536/g' /etc/security/limits.d/20-nproc.conf; \
    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa; \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys; \
    chmod 600 ~/.ssh/authorized_keys ; \
    echo "host localhost user sasdemo password sasDEMO" > ~/.authinfo ; \
    chmod 0600 ~/.authinfo; \
    cp ~/.authinfo /home/sasdemo/.authinfo; \
    chown sasdemo /home/sasdemo/.authinfo; \
    chmod 0600 /home/sasdemo/.authinfo

# anaconda
RUN wget -q -O /tmp/anaconda.shar https://repo.continuum.io/archive/Anaconda${anaVERSION}-Linux-x86_64.sh; \
   bash /tmp/anaconda.shar -p /opt/anaconda3 -b; \
   /opt/anaconda3/bin/conda update conda; \
   /opt/anaconda3/bin/pip install jupyterlab; \
   /opt/anaconda3/bin/pip install sas_kernel; \
   /opt/anaconda3/bin/pip install ${swatRELEASE}/download/v${swatVERSION}/python-swat-${swatVERSION}-linux64.tar.gz; \
   rm /tmp/anaconda.shar



# R
# RUN /opt/anaconda3/bin/conda install r r-essentials

# ENV rstuVERSION=1.1.442 \
#     rswatRELEASE="https://github.com/sassoftware/R-swat/releases"
#     rswatVERSION=1.2.0

# RStudio
# RUN wget -q -O /tmp/rstudio.rpm https://download2.rstudio.org/rstudio-server-rhel-${rstuVERSION}-x86_64.rpm; yum -y install /tmp/rstudio.rpm; rm /tmp/rstudio.rpm
# COPY files/rserver.conf /etc/rstudio/rserver.conf

# R-swat
# RUN yum -y install make; \
#    wget -q -O /tmp/r-swat-1.0.0-linux64.tar.gz https://github.com/sassoftware/R-swat/releases/download/v${rswatVERSION}/r-swat-${rswatVERSION}-linux64.tar.gz; \
#    /opt/anaconda3/bin/R CMD INSTALL /tmp/r-swat-${rswatVERSION}-linux64.tar.gz; \
#    rm -rf /tmp/r-swat-${rswatVERSION}-linux64.tar.gz



# yum-based install of SAS
ENV sasORDER="09M6XJ"
COPY download/$sasORDER/SAS_Viya_deployment_data.zip /tmp/saspb/SAS_Viya_deployment_data.zip
COPY files/install_sas /tmp
RUN /tmp/install_sas

# samples
COPY files/notebooks  /home/sasdemo/notebooks
RUN chown -R sasdemo:sas /home/sasdemo



COPY files/proxy.conf /etc/httpd/conf.d/proxy.conf

HEALTHCHECK CMD curl --fail http://localhost/SASStudio || exit 1

EXPOSE 80

COPY files/start.sh /start.sh

ENTRYPOINT ["/start.sh"]

