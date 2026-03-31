import sqlite3
import os

def migrate():
    # Database path (matching ProductionConfig in config.py)
    base_dir = os.path.abspath(os.path.dirname(__file__))
    db_path = os.path.join(base_dir, 'shapepro.db')
    
    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return

    print(f"Connecting to database at {db_path}...")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    columns_to_add = [
        ('telefone', 'TEXT'),
        ('telefone_verificado', 'BOOLEAN DEFAULT 0'),
        ('otp_code', 'TEXT')
    ]

    for col_name, col_type in columns_to_add:
        try:
            print(f"Adding column '{col_name}'...")
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
            print(f"Column '{col_name}' added successfully.")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e):
                print(f"Column '{col_name}' already exists. Skipping.")
            else:
                print(f"Error adding column '{col_name}': {e}")

    conn.commit()
    conn.close()
    print("Migration finished.")

if __name__ == "__main__":
    migrate()
