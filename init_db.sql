-- Create the database
CREATE DATABASE insta_notifications;

-- Create a new user with the password placeholder
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}' CREATEDB LOGIN;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE insta_notifications TO ${DB_USER};

-- Allow admin to create and edit tables 
GRANT CREATE, USAGE ON SCHEMA public TO ${DB_USER};

-- Allow admin to manage tables they create
ALTER ROLE ${DB_USER} WITH CREATEDB;

-- Make admin database owner
ALTER DATABASE insta_notifications OWNER TO ${DB_USER};
