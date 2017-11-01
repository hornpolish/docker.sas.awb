#FROM dockerhub.artifactory.ai.cba/centos:7
FROM c7-systemd

MAINTAINER Paul Kent "paul.kent@sas.com"
#MAINTAINER Paul Kent "paul.kent@cba.com.au"

# users
# TODO -- use real users
RUN groupadd -g 1001 sas; useradd -u 1001 -g sas sas; useradd -u 1002 -g sas cas; useradd -u 1003 -g sas sasdemo; sh -c 'echo "sasSAS" | passwd "sas" --stdin'; sh -c 'echo "sasCAS" | passwd "cas" --stdin'; sh -c 'echo "sasDEMO" | passwd "sasdemo" --stdin'

# packages

# setup repos and keys
# TODO can i use this directly?  https://artifactory.ai.cba:443/artifactory/remote-epel/RPM-GPG-KEY-EPEL-7
#COPY files/etc/yum.repos.d /etc/yum.repos.d
#COPY files/etc/pki/rpm-gpg /etc/pki/rpm-gpg
#COPY sas-arti.repo /etc/yum.repos.d

# certs
#COPY certs/internal/ /etc/pki/ca-trust/source/anchors/
#RUN update-ca-trust extract

# install pre-reqs
RUN rpmdb --rebuilddb && yum -y install java-1.8.0-openjdk openssh-clients openssh-server glibc libpng12 libXp libXmu net-tools numactl xterm sudo which initscripts iproute lsof git wget bzip2
#RUN yum -y install epel-release
#RUN yum -y install ansible
 
# get systemd going
RUN systemctl enable systemd-user-sessions

# prerequisites
RUN sed -i "/keepcache=/c\keepcache=1" /etc/yum.conf; \
    sh -c 'echo "*     -     nofile     20480" >> /etc/security/limits.conf'; \
    sed -i.bak -e 's/4096/65536/g' /etc/security/limits.d/20-nproc.conf; \
    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa; \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys; \
    chmod 600 ~/.ssh/authorized_keys

# anaconda
ENV anaVERSION 3-5.0.0.1
RUN wget -q -O /tmp/anaconda.shar https://repo.continuum.io/archive/Anaconda${anaVERSION}-Linux-x86_64.sh; bash /tmp/anaconda.shar -p /opt/anaconda3 -b; /opt/anaconda3/bin/conda update conda; \
   /opt/anaconda3/bin/pip install jupyterlab; \
   /opt/anaconda3/bin/pip install sas_kernel; \
   wget -O /tmp/sas.swat.tgz https://github.com/sassoftware/python-swat/releases/download/v1.2.0/python-swat-1.2.0-linux64.tar.gz; \
   /opt/anaconda3/bin/pip install /tmp/sas.swat.tgz

# samples
RUN mkdir /opt/notebooks
COPY files/titanic.ipynb /opt/notebooks

# R 
RUN /opt/anaconda3/bin/conda install r r-essentials 

# RStudio
# RUN wget -q -O /tmp/rstudio.rpm https://download2.rstudio.org/rstudio-server-rhel-1.0.153-x86_64.rpm; yum -y install /tmp/rstudio.rpm; 
# COPY files/rserver.conf /etc/rstudio/rserver.conf

# R-swat
RUN yum -y install make; \
    wget -q -O /tmp/r-swat-1.0.0-linux64.tar.gz https://github.com/sassoftware/R-swat/releases/download/v1.0.0/r-swat-1.0.0-linux64.tar.gz; \
    /opt/anaconda3/bin/R CMD INSTALL /tmp/r-swat-1.0.0-linux64.tar.gz

# yum-based install of SAS
ENV sasVERSION 09LGBW.1013/
ENV sasORDER   09LGBW
COPY download/$sasVERSION/sas_viya_playbook /opt/saspb

# manual edits for yum -y and comment out apply_license ..
# aaaand .. install it then.
RUN sed -i "s/yum /yum -y /g" /opt/saspb/customized_deployment_script.sh; \
    sed -i "/apply_license/d" /opt/saspb/customized_deployment_script.sh; \
    mkdir -p /etc/pki/sas/private; \
    cd /opt/saspb && ./customized_deployment_script.sh

COPY download/$sasVERSION/sas_viya_playbook/SASViyaV0300_${sasORDER}_Linux_x86-64.txt /opt/sas/viya/config/etc/cas/default/SASViyalic.txt

RUN /opt/sas/spre/home/SASFoundation/utilities/bin/apply_license /opt/sas/viya/config/etc/cas/default/SASViyalic.txt

RUN sed -i '/env.CAS_LICENSE/c\env.CAS_LICENSE = config_loc .. "/SASViyalic.txt"' /opt/sas/viya/config/etc/cas/default/casconfig.lua

RUN /opt/sas/spre/home/SASFoundation/utilities/bin/post_install build_registry

# postinstall steps

# skip httd for now
# RUN yum -y install httpd mod_ssl
# COPY files/proxy.conf /etc/httpd/conf.d/proxy.conf
# RUN systemctl restart httpd.service

RUN sed -i "s/\${ADMIN_USER}/cas/g" /opt/sas/viya/config/etc/cas/default/perms.xml

RUN cp /opt/sas/viya/home/SASFoundation/utilities/bin/sas-cascontroller.init /etc/rc.d/init.d/sas-viya-cascontroller-default; \
    chown sas:sas /etc/rc.d/init.d/sas-viya-cascontroller-default; \
    /sbin/chkconfig --add /etc/rc.d/init.d/sas-viya-cascontroller-default

CMD ["/usr/sbin/init"]
