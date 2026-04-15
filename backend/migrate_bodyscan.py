import sqlite3
import os

db_path = r'c:\Users\mae12\.gemini\antigravity\scratch\shapepro\backend\instance\shapepro.db'

def migrate():
    if not os.path.exists(db_path):
        print(f"Error: Database not found at {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Check if metrics column already exists
        cursor.execute("PRAGMA table_info(body_scans)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'metrics' not in columns:
            print("Adding 'metrics' column to 'body_scans' table...")
            cursor.execute("ALTER TABLE body_scans ADD COLUMN metrics JSON")
            conn.commit()
            print("Migration successful.")
        else:
            print("'metrics' column already exists.")
            
    except Exception as e:
        print(f"Migration failed: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
