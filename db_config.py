import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

def db_config():
    db_configuration = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": 5432,
        "database": "insta_notifications",
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASS")
    }

    try: 
        connection = psycopg2.connect(**db_configuration)
        return connection
    except Exception as e:
        print("Exception found: ", e)
