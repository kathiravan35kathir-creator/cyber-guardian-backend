import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

print("🔥 DATABASE_URL Loaded:", DATABASE_URL)

def get_db_connection():
    conn = psycopg2.connect(DATABASE_URL)
    return conn


def init_db():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS threats (
            id SERIAL PRIMARY KEY,
            type VARCHAR(50),
            input_text TEXT,
            status VARCHAR(20),
            risk_score INT,
            reasons TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """)

        conn.commit()
        cursor.close()
        conn.close()
        print("✅ Database initialized successfully")

    except Exception as e:
        print("❌ Database init error:", e)
