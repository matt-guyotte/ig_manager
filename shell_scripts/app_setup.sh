#!/bin/bash

# NOTE: To run this setup file, you need to make the file 
# executable first using the 'chmod +x app_setup.sh' command.
# Then, you can run this using 'sudo ./app_setup.sh'.

# Prompt for database password (or generate one)
read -p "Enter your instagram username: " INSTA_USER
echo 
read -sp "Enter your instagram password (this will only be stored locally, and not exposed to outside servers.): " INSTA_PASS
echo
echo "Instagram credentials added to .env."

read -p "Create your database username (save if needed): " DB_USER
echo
read -sp "Create your database password (save if needed): " DB_PASS
echo
read -p "Enter your ubuntu username (might just be unbuntu): " UBUNTU_USER
echo
read -p "Enter your app url without https:// : " APP_URL
echo "This database will be named 'insta_notifications'.
    Please save your username and password if you need to 
    log in to the psql server."


cat <<EOF > ../.env
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_NAME="insta_notifications"
DB_HOST="localhost"
DB_PORT="5432"
INSTA_USER="$INSTA_USER"
INSTA_PASS="$INSTA_PASS"
CHROMEDRIVER_PATH="/usr/local/bin/chromedriver"
CHROME_BINARY_PATH = "/usr/bin/google-chrome"
PYTESSERACT_PATH = "/usr/bin/tesseract"
EOF

#Setting read and write permission to owner only
chmod 600 ../.env

echo ".env file created with db and insta credentials."

#exporting variables to be used in database creation
export DB_USER DB_PASS

# Load environment variables
#source .env

# Update and install PostgreSQL, psycopg2 adapter
echo "Updating system and installing PostgreSQL..."
sudo apt update && sudo apt install -y postgresql postgresql-contrib libpq-dev

# Start and enable PostgreSQL
if ! systemctl is-active --quiet postgresql; then
    sudo systemctl start postgresql
fi
sudo systemctl enable postgresql

# Create the .pgpass file and set appropriate permissions
PGPASS_FILE="$HOME/.pgpass"
echo "localhost:5432:insta_notifications:$DB_USER:$DB_PASS" > $PGPASS_FILE
chmod 0600 $PGPASS_FILE

echo ".pgpass file created."

echo "Configuring database with provided credentials..."
# Replace placeholders in init_db with .env values 
envsubst < init_db.sql | sudo -u postgres psql

# Creating notifications and deleted_notifications tables
PGPASS_FILE="$HOME/.pgpass" psql -h localhost -U $DB_USER -d insta_notifications -f create_tables.sql

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

echo "Database setup complete!"

echo "This database will be named "insta_notifications".
    Please save your username and password if you need to 
    log in to the psql server."

echo "Now creating python virtual environment (venv)."

# Installing python, pip, and venv if not available.
sudo apt install -y python3 python3-pip python3-venv

# Install Pytesseract if not available.
sudo apt install -y tesseract-ocr
sudo apt install -y libtesseract-dev

#Creating virtual environment 
python3 -m venv ../venv

#Running virtual environment
source /home/$UBUNTU_USER/ig_manager/venv/bin/activate

echo "Virtual environment now created. Now installing necessary dependencies."

#Installing python dependencies
pip install -r ../requirements.txt

#install wget and unzip if not available
sudo apt install -y wget
sudo apt install -y unzip

#setting up chrome for selenium
if ! command -v google-chrome-stable &> /dev/null
then
    echo "Google Chrome not found. Executing your task..."
    # Put the command you want to execute here
    # For example:
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb
    sudo apt-get install -f
else
    echo "Google Chrome is already installed."
fi

#installing chromedriver based on current version
CHROME_VERSION=$(google-chrome-stable --version | awk '{print $3}')
wget https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VERSION/linux64/chromedriver-linux64.zip

#extracting zip file and moving to bin
unzip chromedriver-linux64.zip
sudo mv chromedriver-linux64/chromedriver /usr/local/bin/

#remove excess chrome and chromedriver files
sudo rm -rf chromedriver-linux64
sudo rm chromedriver-linux64.zip
sudo rm google-chrome-stable_current_amd64.deb

#set chrome to be executable and set permissions
sudo chmod +x /usr/bin/google-chrome
sudo chmod +x /usr/local/bin/chromedriver
sudo chown $UBUNTU_USER:www-data /usr/bin/google-chrome
sudo chmod 775 /usr/bin/google-chrome
sudo chown $UBUNTU_USER:www-data /usr/local/bin/chromedriver
sudo chmod 775 /usr/local/bin/chromedriver

# Create the gunicorn.service file
echo "Creating Gunicorn systemd service at $SERVICE_FILE..."

# add www-data role to current user
sudo usermod -aG www-data $UBUNTU_USER

# double check permissions for dir
sudo chown -R $UBUNTU_USER:www-data /home/$UBUNTU_USER/ig_manager
sudo chmod -R 750 /home/$UBUNTU_USER/ig_manager

# Path to systemd service file
SERVICE_FILE="/etc/systemd/system/ig_manager.service"

cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=gunicorn daemon for ig_manager
After=network.target

[Service]
User=$UBUNTU_USER
Group=$UBUNTU_USER
WorkingDirectory=/home/$UBUNTU_USER/ig_manager
ExecStart=/home/$UBUNTU_USER/ig_manager/venv/bin/gunicorn --workers 3 --bind unix:/tmp/ig_manager.sock --timeout 120 main:app --access-logfile - --error-logfile -
ExecStopPost=/bin/sh -c "sudo pkill -9 chrome; sudo pkill -9 chromedriver"
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=10
TimeoutStopSec=80
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF

echo "Gunicorn service file created successfully at $SERVICE_FILE"

# Reload systemd to pick up the new service
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable and start the service
echo "Starting Gunicorn service..."
sudo systemctl daemon-reload
sudo systemctl enable ig_manager
sudo systemctl start ig_manager

# set permissions for socket and var/run dir
sudo chown $UBUNTU_USER:www-data /tmp/ig_manager.sock
sudo chmod 770 /tmp/ig_manager.sock
sudo chown $UBUNTU_USER:www-data /tmp
sudo chmod 770 /tmp

 #install nginx if not already configured
sudo apt install -y nginx

#configure nginx to add site     
cat << EOF | sudo tee /etc/nginx/sites-available/ig_manager
server {
    listen 80;
    server_name $APP_URL;

    location / {
        proxy_pass http://unix:/tmp/ig_manager.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/ig_manager /etc/nginx/sites-enabled

sudo systemctl start nginx
sudo systemctl enable nginx

echo "nginx file created and linked."

# Setup cron jobs
# 1 - Runs main route every 10 minutes
# 2 - Clears the deleted notifications table every Sunday
CRON_JOBS="
*/20 * * * * bin/bash -c 'sleep $((RANDOM % 1200)) && curl http://$APP_URL/main >> /home/$UBUNTU_USER/ig_manager/cron.log 2>&1'
0 0 * * 0 curl http://$APP_URL/clear_deleted_notifs >> /home/$UBUNTU_USER/ig_manager/cron.log 2>&1
"

# Load current cron jobs, append new ones, and update the crontab
( crontab -l 2>/dev/null; echo "$CRON_JOBS" ) | crontab -

# Print out the current cron jobs to confirm
echo "Current cron jobs:"
crontab -l

#make the cron commmands executable
chmod +x /home/$UBUNTU_USER/ig_manager/cron.log

#final clear to reset any processes
sudo systemctl daemon-reload
sudo systemctl restart ig_manager
sudo systemctl restart nginx

echo "App setup complete. You will need to cd in and out of the directory to see
    the venv. Once back in use the "source venv/bin/activate" command to start the venv.
    It's up to you if you would like to use a reverse proxy or call the flask app directly 
    using 'python3 main.py' at this point."
