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
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=insta_notifications
DB_HOST=localhost
DB_PORT=5432
INSTA_USER=$INSTA_USER
INSTA_PASS=$INSTA_PASS
EOF

#Setting read and write permission to owner only
chmod 600 .env

echo ".env file created with db and insta credentials."

cat .env

export DB_USER DB_PASS

# Load environment variables
source .env

# Update and install PostgreSQL
echo "Updating system and installing PostgreSQL..."
sudo apt update && sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
if ! systemctl is-active --quiet postgresql; then
    sudo systemctl start postgresql
fi
sudo systemctl enable postgresql

# Replace placeholders in init_db with .env values 
echo "Configuring database with provided credentials..."
envsubst < init_db.sql | sudo -u postgres psql

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

echo "App setup complete. It's up to you if you would like to use a 
    reverse proxy or call the flask app directly using 'python3 main.py'
    at this point."
