# Background
A docker container for a data scientist. (awb - analytics work bench).  take your pick of
* SAS Studio
* R Studio
* Jupyter Lab

# How to run (from docker.sas.com)
    docker pull docker.sas.com/kent/viya.awb:w47
    docker run -d --name viya -p 8777:8777 -p 17551:17551 -p 7080:7080 -p 8888:8888 -p 5570:5570 --privileged \
       --cap-add SYS_ADMIN -v /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro --rm \
       docker.sas.com/kent/viya.awb:w47

To check the services are all started:

    # There should be 4 services and status should be 'up'
    docker exec -ti viya /etc/init.d/sas-viya-all-services status

Jupyter is not started by default, start it up using

    docker exec -ti viya /opt/anaconda3/bin/jupyter notebook --no-browser --ip 0.0.0.0

Or just use "run.sh" once you have pulled the image from docker.sas.com

    
Once they are all up, you can access these links (where `host` is the machine you ran `docker run`):
* http://host:8777 for CAS Monitor
* http://host:7080 for SAS Studio
* http://host:8888 for Jupyter



