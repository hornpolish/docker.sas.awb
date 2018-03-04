#!/bin/bash

# name: start.sh
# thanks jozwal for the ideas

# Start Viya
#/etc/init.d/sas-viya-all-services start

# NOTE: As of 9-14 programming-only deployment includes some unnecessary microservices.
#	Remove unnecessary services and start remaining (in order)
rm -f /etc/init.d/sas-viya-alert-track-default
rm -f /etc/init.d/sas-viya-backup-agent-default
rm -f /etc/init.d/sas-viya-ops-agent-default
rm -f /etc/init.d/sas-viya-watch-log-default

/etc/init.d/sas-viya-all-services start

#############################
#
# Update httpd configuration
#
#############################

# Set servername to match container name
echo "ServerName $(hostname -i):80" >> /etc/httpd/conf/httpd.conf

# Replace container name inserted during image build
# TODO: Just replace with "localhost" when building image?
sed -i "s/\/\/.*:/\/\/localhost:/g" /etc/httpd/conf.d/proxy.conf

# Add reverse proxy rules for Jupyter
# NOTE: location needs to match that given in --NotebookApp.base_url when launching server
cat >> /etc/httpd/conf.d/proxy.conf <<'EOF'
<Location /SASStudio>
ProxyPass        http://localhost:7080/SASStudio
ProxyPassReverse http://localhost:7080/SASStudio
RequestHeader set Origin "http://localhost:7080"
</Location>

<Location /Jupyter>
ProxyPass        http://localhost:8888/Jupyter
ProxyPassReverse http://localhost:8888/Jupyter
RequestHeader set Origin "http://localhost:8888"
</Location>

<Location /Jupyter/api/kernels/>
ProxyPass        ws://localhost:8888/Jupyter/api/kernels/
ProxyPassReverse ws://localhost:8888/Jupyter/api/kernels/
</Location>

<Location /Jupyter/terminals/>
ProxyPass        ws://localhost:8888/Jupyter/terminals/
ProxyPassReverse ws://localhost:8888/Jupyter/terminals/
</Location>

#<Location /RStudio>
#ProxyPass        ws://localhost:8787
#ProxyPass        http://localhost:8787
#ProxyPassReverse ws://localhost:8787
#ProxyPassReverse http://localhost:8787
#RequestHeader set Origin "http://localhost:8787"
#</Location>

#<Location /auth-sign-in>
#ProxyPass        http://localhost:8787/auth-sign-in
#ProxyPassReverse http://localhost:8787/auth-sign-in
#</Location>


EOF

# Start RStudio Server
# /usr/lib/rstudio-server/bin/rserver --server-daemonize 0 &

# Start httpd
httpd

# Start Jupyter
export PATH=$PATH:/opt/anaconda3/bin
su -c 'jupyter-notebook --ip="*" --no-browser --notebook-dir=/home/sasdemo --NotebookApp.base_url=/Jupyter' sasdemo &

# Give Jupyter enough time to spit out messages
sleep 5

# Write out a help page to be displayed when browsing port 80
cat > /var/www/html/index.html <<'EOF'
<html>
 <h1> SAS Viya 3.3 Docker Container </h1>
 <p> Access the software by browsing to:
 <ul>
  <li> <b><a href="/SASStudio">/SASStudio</a></b>
  <li> <b><a href="/RStudio/auth-sign-in">/RStudio</a></b>
  <li> <b><a href="/Jupyter">/Jupyter</a></b>
 </ul> using HTTP on port 80.

 <p> If port 80 is forwarded to a different port on the host machine, use the host port instead.

 <p> Use the <b>sasdemo</b> / <b>sasDEMO</b> login to access SAS Studio, CAS, and Jupyter.
</html>
EOF

# Print out the help message without the HTML tags
sed 's/<[^>]*>//g' /var/www/html/index.html

while true
do
  tail -f /dev/null & wait ${!}
done

