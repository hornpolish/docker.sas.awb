!#/bin/bash

set -x

#docker build -t viya.awb .

docker run -d --name viya -p 8777:8777 -p 17551:17551 -p 7080:7080 -p 8888:8888 -p 5570:5570 --privileged \
       --cap-add SYS_ADMIN -v /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro --rm \
       docker.sas.com/kent/viya.awb:w47

sleep 10

echo /opt/anaconda3/bin/jupyter-notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root
docker exec -ti viya bash
