# Background
A docker container for a data scientist. (awb - analytics work bench).  take your pick of
* SAS Studio
* R Studio
* Jupyter Lab

# How to build

    ORDER={6-digit-SAS-order-number}
    mkdir -p download/$ORDER
    copy "SAS_Viya_deployment_data.zip" attachment from SAS Order email into download/$ORDER
    edit $ORDER into sasORDER ENV variable in Dockerfile
    docker-compose build

# How to run

    docker-compose up

To check the services are all started:

    # There should be 4 services and status should be 'up'
    ./dostatus


    
Once they are all up, you can access these links (substitute `localhost` maybe)
* http://localhost:80/cas for CAS Monitor
* http://localhost:80/SASStudio for SAS Studio
* http://localhost:80/Jupyter for Jupyter

# Registry details
You may see references to "docker.sas.com/kent/..." -- that is the internal docker registry inside the SAS firewall.  You'll want to substitute your own registry here.

# Support
This is an example for you to use and change as you see fit.  Probably you don't want hard coded passwords like we use here.  



