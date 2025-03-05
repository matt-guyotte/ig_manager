def clear_deleted_notifs(connection):
    cursor = connection.cursor()
    clear_query = """
        DELETE FROM deleted_notifications
    """
    try:
        cursor.execute(clear_query)
        connection.commit()
    except Exception as e: 
        connection.rollback()
        print("Exception found: ", e)
    finally:
        cursor.close()
