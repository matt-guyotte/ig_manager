def get_notifs(connection):
    cursor = connection.cursor()
    get_query = """
        SELECT * FROM notifications
    """
    try:
        cursor.execute(get_query)
        rows = cursor.fetchall()
        column_names = [desc[0] for desc in cursor.description]
        result = [dict(zip(column_names, row)) for row in rows]
        connection.commit()
        return result
    except Exception as e: 
        connection.rollback()
        print("Exception found: ", e)
    cursor.close()
    return(0)
