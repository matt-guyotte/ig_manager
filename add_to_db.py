def add_to_db(notifications, connection):
    cursor = connection.cursor()
    for notif in notifications:
        text = notif['text']
        _type = notif['_type']
        names = notif['names']

        check_query = """
            SELECT EXISTS (
                SELECT 1 FROM notifications
                WHERE text = %s
            )
            OR EXISTS (
                SELECT 1 FROM deleted_notifications
                WHERE text = %s
            );
        """

        add_query = """
            INSERT INTO notifications (text, type, names)
            VALUES (%s, %s, %s);
        """

        try:
            cursor.execute(check_query, (text, text))
            exists = cursor.fetchone()[0]
            if not exists:
                cursor.execute(add_query, (text, _type, names))
            connection.commit()
        except Exception as e: 
            connection.rollback()
            print("Exception found: ", e)
    cursor.close()
    return(0)
