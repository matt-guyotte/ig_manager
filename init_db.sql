-- Create the database
CREATE DATABASE insta_notifications;

-- Create a new user with the password placeholder
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD ${DB_PASS};

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE insta_notifications TO ${DB_USER};

-- Create notifications table
CREATE TABLE notifications (
    text VARCHAR(1000),
    type VARCHAR(10),
    names TEXT[]
)

-- Create deleted notificiations table
CREATE TABLE deleted_notifications (
    text VARCHAR(1000),
    type VARCHAR(10),
    names TEXT[]
)
