import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

def db_config():
    db_configuration = {
        "host": "localhost",
        "port": 5432,
        "database": "insta_notifications",
        "user": "admin",
        "password": os.getenv("DB_PASS")
    }

    try: 
        connection = psycopg2.connect(**db_configuration)
        return connection
    except Exception as e:
        print("Exception found: ", e)
