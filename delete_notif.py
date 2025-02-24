def delete_notif(connection, notif):
    cursor = connection.cursor()
    find_query = """
        SELECT * FROM notifications
        WHERE text = %s
        LIMIT 1;
    """
    add_query = """
        INSERT INTO deleted_notifications (text, type, names)
        VALUES(%s, %s, %s);
    """
    delete_query = """
        DELETE FROM notifications
        WHERE text = %s;
    """
    try: 
        cursor.execute(find_query, (notif,))
        row = cursor.fetchone()
        column_names = [column[0] for column in cursor.description]
        result = dict(zip(column_names, row))
        cursor.execute(add_query, (result["text"], result["type"], result["names"]))
        cursor.execute(delete_query, (notif,))
        connection.commit()
    except Exception as e: 
        print("Exception found: ", e)
    finally:
        cursor.close()
