# Background
A docker container for a data scientist. (awb - analytics work bench).  take your pick of
* SAS Studio
* R Studio
* Jupyter Lab

# How to build
    ORDER={6-digit-SAS-order-number}
    mkdir download/$ORDER
    edit $ORDER into sasORDER variable in Dockerfile
    docker-compose build

# How to run (from docker.sas.com)
    docker-compose up

To check the services are all started:

    # There should be 4 services and status should be 'up'
    ./dostatus

Jupyter is not started by default, start it up using

    ./dojupy


    
Once they are all up, you can access these links (where `host` is the machine you ran `docker run`):
* http://localhost:80/cas for CAS Monitor
* http://localhost:80/SASStudio for SAS Studio
* http://localhost:80/Jupyter for Jupyter



