from database import get_db_connection

try:
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT NOW();")
    print("✅ DB Connected Successfully:", cursor.fetchone())

    cursor.close()
    conn.close()

except Exception as e:
    print("❌ DB Connection Failed:", e)
