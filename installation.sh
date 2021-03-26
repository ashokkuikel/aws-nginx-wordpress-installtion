#Download the latest version of WordPress and extract the files to the /opt/bitnami/wordpress/ directory:

cd /tmp
wget https://wordpress.org/latest.tar.gz
sudo tar xfvz latest.tar.gz -C /opt/bitnami/

#Run the following commands to assign the necessary directory permissions:

sudo chown -R bitnami:daemon /opt/bitnami/wordpress
sudo chmod -R g+w /opt/bitnami/wordpress

#Create and edit the /opt/bitnami/nginx/conf/server_blocks/wordpress-server-block.conf file and add the configuration block shown below

server {
    listen 80 default_server;
    root /opt/bitnami/wordpress;
    # Catch-all server block
    # See: https://nginx.org/en/docs/http/server_names.html#miscellaneous_names
    server_name _;

    index index.php;

    location / {
      try_files $uri $uri/ /index.php?q=$uri&$args;
    }

    if (!-e $request_filename)
    {
      rewrite ^/(.+)$ /index.php?q=$1 last;
    }

    include  "/opt/bitnami/nginx/conf/bitnami/*.conf";
  }
  
  #Create and edit the /opt/bitnami/nginx/conf/server_blocks/wordpress-https-server-block.conf file and add the configuration block shown below
   server {
      # Port to listen on, can also be set in IP:PORT format
      listen 443 ssl default_server;
      root /opt/bitnami/wordpress;
      # Catch-all server block
      # See: https://nginx.org/en/docs/http/server_names.html#miscellaneous_names
      server_name _;
      ssl_certificate      bitnami/certs/server.crt;
      ssl_certificate_key  bitnami/certs/server.key;
      location / {
        try_files $uri $uri/ /index.php?q=$uri&$args;
      }
      if (!-e $request_filename)
      {
        rewrite ^/(.+)$ /index.php?q=$1 last;
      }
      include  "/opt/bitnami/nginx/conf/bitnami/*.conf";
  }
  
#Restart NGINX:

sudo /opt/bitnami/ctlscript.sh restart nginx


#Step 1: Install The Lego Client
#The Lego client simplifies the process of Let’s Encrypt certificate generation. To use it, follow these steps:
#Log in to the server console as the bitnami user.

#Run the following commands to install the Lego client. Note that you will need to replace the X.Y.Z placeholder with the actual version number of the downloaded archive: cd /tmp

curl -Ls https://api.github.com/repos/xenolf/lego/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4 | wget -i -

# X.Y.Z represents the package version and current lego file name
tar xf lego_vX.Y.Z_linux_amd64.tar.gz
sudo mkdir -p /opt/bitnami/letsencrypt
sudo mv lego /opt/bitnami/letsencrypt/lego

#Turn off all Bitnami services:

sudo /opt/bitnami/ctlscript.sh stop

#request a new certficate
sudo /opt/bitnami/letsencrypt/lego --tls --email="noreply@ashokkuikel.com" --domains="ashokkuikel.com" --domains="www.ashokkuikel.com" --path="/opt/bitnami/letsencrypt" run

#Agree to the terms of service.
Y


sudo mv /opt/bitnami/nginx/conf/bitnami/certs/server.crt /opt/bitnami/nginx/conf/bitnami/certs/server.crt.old
sudo mv /opt/bitnami/nginx/conf/bitnami/certs/server.key /opt/bitnami/nginx/conf/bitnami/certs/server.key.old
sudo mv /opt/bitnami/nginx/conf/bitnami/certs/server.csr /opt/bitnami/nginx/conf/bitnami/certs/server.csr.old
sudo ln -sf /opt/bitnami/letsencrypt/certificates/ashokkuikel.com.key /opt/bitnami/nginx/conf/bitnami/certs/server.key
sudo ln -sf /opt/bitnami/letsencrypt/certificates/ashokkuikel.com.crt /opt/bitnami/nginx/conf/bitnami/certs/server.crt
sudo ln -sf /opt/bitnami/letsencrypt/certificates/www.ashokkuikel.com.key /opt/bitnami/nginx/conf/bitnami/certs/server.key
sudo ln -sf /opt/bitnami/letsencrypt/certificates/www.ashokkuikel.com.crt /opt/bitnami/nginx/conf/bitnami/certs/server.crt
sudo chown root:root /opt/bitnami/nginx/conf/bitnami/certs/server*
sudo chmod 600 /opt/bitnami/nginx/conf/bitnami/certs/server*

#Restart all Bitnami services:

sudo /opt/bitnami/ctlscript.sh start

#Renew The Let’s Encrypt Certificate

#To automatically renew your certificates before they expire, write a script to perform the above tasks and schedule a cron job to run the script periodically. To do this:
#Create a script at /opt/bitnami/letsencrypt/scripts/renew-certificate.sh
sudo mkdir -p /opt/bitnami/letsencrypt/scripts
sudo nano /opt/bitnami/letsencrypt/scripts/renew-certificate.sh


#For NGINX:

#!/bin/bash

sudo /opt/bitnami/ctlscript.sh stop nginx
sudo /opt/bitnami/letsencrypt/lego --tls --email="noreply@ashokkuikel.com" --domains="ashokkuikel.com" --domains="www.ashokkuikel.com" --path="/opt/bitnami/letsencrypt" renew --days 90
sudo /opt/bitnami/ctlscript.sh start nginx

#Make the script executable:

sudo chmod +x /opt/bitnami/letsencrypt/scripts/renew-certificate.sh

#Execute the following command to open the crontab editor:

sudo crontab -e

#Add the following lines to the crontab file and save it:
0 0 1 * * /opt/bitnami/letsencrypt/scripts/renew-certificate.sh 2> /dev/null
