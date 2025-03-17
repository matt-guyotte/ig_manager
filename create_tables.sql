-- Create notifications table
CREATE TABLE notifications (
    text VARCHAR(1000),
    type VARCHAR(10),
    names TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create deleted notificiations table
CREATE TABLE deleted_notifications (
    text VARCHAR(1000),
    type VARCHAR(10),
    names TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
