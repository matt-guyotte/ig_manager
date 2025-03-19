read -p "Enter your app url without https:// : " APP_URL
echo 

# Install openssl if not already available
sudo apt update
sudo apt -y install openssl

# Generate private key for certificate
openssl genpkey -algorithm RSA -out /etc/ssl/private/ig_manager.key -aes256

# Generate certificate signing request
openssl req -new -key /etc/ssl/private/ig_manager.key -out /etc/ssl/certs/ig_manager.csr

# Generate certificate
openssl x509 -req -in /etc/ssl/certs/ig_manager.csr -signkey /etc/ssl/private/ig_manager.key -out /etc/ssl/certs/ig_manager.crt -days 9999

# Make sure private key has proper permissions to be accessed later
sudo chmod 600 /etc/ssl/private/ig_manager.key

# Update nginx to use ssl
cat << EOF | sudo tee /etc/nginx/sites-available/ig_manager
server {
    listen 443 ssl;
    server_name $APP_URL;

    ssl_certificate /etc/ssl/certs/ig_manager.crt;
    ssl_certificate_key /etc/ssl/private/ig_manager.key;

    location / {
        proxy_pass http://unix:/tmp/ig_manager.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 80;
    server_name $APP_URL;

    return 301 https://\$host\$request_uri;
}
EOF

sudo chown root:www-data /etc/ssl/certs/ig_manager.crt
sudo chown root:www-data /etc/ssl/private/ig_manager.key
sudo chmod 600 /etc/ssl/private/ig_manager.key

sudo systemctl restart nginx

echo "If there there is a password error with nginx at this point, refer to the 'further setup' instructions at the bottom of the shell_scripts/add_https.sh file."

#FURTHER SETUP (if errors occur):

#Need to add this line to nginx conf file
#ssl_password_file /etc/ssl/private/ssl_passphrase.txt;

#Then create the file with your just your passphrase
#sudo nano /etc/ssl/private/ssl_passphrase.txt

#Restart nginx to apply changes 
#sudo systemctl restart nginx
