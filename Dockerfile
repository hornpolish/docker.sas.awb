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
RUN sed -i "/keepcache=/c\keepcache=1" /etc/yum.conf; sh -c 'echo "*     -     nofile     20480" >> /etc/security/limits.conf'; sed -i.bak -e 's/4096/65536/g' /etc/security/limits.d/20-nproc.conf; ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa; cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys

# anaconda
RUN wget -O /tmp/anaconda.shar https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh; bash /tmp/anaconda.shar -p /opt/anaconda3 -b; /opt/anaconda3/bin/conda update conda; 
RUN /opt/anaconda3/bin/pip install jupyterlab
RUN /opt/anaconda3/bin/pip install sas_kernel
RUN wget -O /tmp/sas.swat.tgz https://github.com/sassoftware/python-swat/releases/download/v1.2.0/python-swat-1.2.0-linux64.tar.gz; /opt/anaconda3/bin/pip install /tmp/sas.swat.tgz

# yum-based install of SAS
COPY download/sas_viya_playbook /opt/saspb

RUN mkdir -p /etc/pki/sas/private && cd /opt/saspb && ./customized_deployment_script.sh

COPY download/sas_viya_playbook/SASViyaV0300_09L4JG_Linux_x86-64.txt /opt/sas/viya/config/etc/cas/default/

RUN /opt/sas/spre/home/SASFoundation/utilities/bin/apply_license /opt/sas/viya/config/etc/cas/default/SASViyaV0300_09L4JG_Linux_x86-64.txt sas

RUN sed -i '/env.CAS_LICENSE/c\env.CAS_LICENSE = config_loc .. "SASViyaV0300_09L4JG_Linux_x86-64.txt"' /opt/sas/viya/config/etc/cas/default/casconfig.lua

RUN /opt/sas/viya/home/SASFoundation/utilities/bin/post_install build_registry
RUN /opt/sas/spre/home/SASFoundation/utilities/bin/post_install build_registry

CMD ["/usr/sbin/init"]
