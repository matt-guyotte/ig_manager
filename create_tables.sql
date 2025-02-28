-- Create notifications table
CREATE TABLE notifications (
    text VARCHAR(1000),
    type VARCHAR(10),
    names TEXT[]
);

-- Create deleted notificiations table
CREATE TABLE deleted_notifications (
    text VARCHAR(1000),
    type VARCHAR(10),
    names TEXT[]
);
