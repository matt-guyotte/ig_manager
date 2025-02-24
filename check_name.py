def check_name(connection, name):
    cursor = connection.cursor()
    check_query = """
        SELECT COUNT(*) FROM notifications
        WHERE %s = ANY(names);
    """
    cursor.execute(check_query, (name,))
    result = cursor.fetchone()[0]
    cursor.close()
    return result

