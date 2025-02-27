-- Create the database
CREATE DATABASE insta_notifications;

-- Create a new user with the password placeholder
CREATE USER '${DB_USER}' WITH ENCRYPTED PASSWORD '${DB_PASS}';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE insta_notifications TO admin;
