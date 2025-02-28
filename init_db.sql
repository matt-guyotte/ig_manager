-- Create the database
CREATE DATABASE insta_notifications;

-- Create a new user with the password placeholder
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE insta_notifications TO ${DB_USER};

-- Allow admin to create and edit tables 
GRANT CREATE ON SCHEMA public TO ${DB_USER};
