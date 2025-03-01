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

read -p "Enter your database username: " DB_USER
echo
read -sp "Enter your database password: " DB_PASS
echo
echo "This database will be named 'insta_notifications'.
    Please save your username and password if you need to 
    log in to the psql server."


cat <<EOF > .env
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_NAME="insta_notifications"
DB_HOST="localhost"
DB_PORT="5432"
INSTA_USER="$INSTA_USER"
INSTA_PASS="$INSTA_PASS"
CHROMEDRIVER_PATH="/usr/bin/chromedriver"
EOF

#Setting read and write permission to owner only
chmod 600 .env

echo ".env file created with db and insta credentials."

#exporting variables to be used in database creation
export DB_USER DB_PASS

# Load environment variables
#source .env

# Update and install PostgreSQL
echo "Updating system and installing PostgreSQL..."
sudo apt update && sudo apt install -y postgresql postgresql-contrib

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

#Creating virtual environment 
python3 -m venv venv

#Running virtual environment
source venv/bin/activate

echo "Virtual environment now created. Now installing necessary dependencies."

#Installing python dependencies
pip install -r requirements.txt

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
wget https://chromedriver.storage.googleapis.com/$CHROME_VERSION/chromedriver_linux64.zip

#extracting zip file and moving to bin
unzip chromedriver_linux64.zip
sudo mv chromedriver /usr/local/bin/
sudo chmod +x /usr/local/bin/chromedriver

echo "App setup complete. It's up to you if you would like to use a 
    reverse proxy or call the flask app directly using 'python3 main.py'
    at this point."
