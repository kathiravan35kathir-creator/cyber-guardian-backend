from database import get_db_connection

try:
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM threats;")
    count = cursor.fetchone()[0]

    print("✅ Total rows in threats table:", count)

    cursor.execute("SELECT * FROM threats ORDER BY id DESC LIMIT 5;")
    rows = cursor.fetchall()

    print("✅ Last 5 rows:")
    for row in rows:
        print(row)

    cursor.close()
    conn.close()

except Exception as e:
    print("❌ Error:", e)
