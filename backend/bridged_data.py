import asyncio
import sqlite3
import bcrypt
import time

# Initialize global variable for the fixed salt
FixedSalt = None

# Shared arrays
ws_slaves = []
ws_clients = []
slaves = []
clients = []
users = []

# Shared database lock and queue
databaselocked = False
dbActions = []


# Initialize the database with ownerid and fixed salt
def initialize_db():
    global FixedSalt
    with sqlite3.connect("database.db") as conn:
        cursor = conn.cursor()

        # Create users table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userid TEXT NOT NULL UNIQUE,
            registeredIP TEXT,
            lastknownIP TEXT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            ownerid TEXT NOT NULL,
            is_administrator INTEGER DEFAULT 0  -- 0 for regular user, 1 for admin)
            """)


        # Create internals table for storing the salt
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS internals (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
        """)

        # Check if the salt already exists in the database
        cursor.execute("SELECT value FROM internals WHERE key = 'fixed_salt'")
        result = cursor.fetchone()

        if result:
            # Load the existing salt
            FixedSalt = result[0].encode()
            print("Loaded fixed salt from database.")
        else:
            # Generate a new salt and store it
            FixedSalt = bcrypt.gensalt()
            cursor.execute("INSERT INTO internals (key, value) VALUES ('fixed_salt', ?)", (FixedSalt.decode(),))
            print("Generated and stored new fixed salt in database.")

        conn.commit()


# Queue a database action
""""
def queueDBAction(action):
    global dbActions
    dbActions.append(action)
"""

def DBProcessor(cmd, params=None):
    global databaselocked
    while databaselocked:  # Wait until the database is unlocked
        time.sleep(1)
    databaselocked = True  # Lock the database
    try:
        with sqlite3.connect("database.db") as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(cmd, params)  # Execute with parameters
            else:
                cursor.execute(cmd)  # Execute without parameters
            conn.commit()
            
            # If the query is a SELECT, return the results
            if cmd.strip().upper().startswith("SELECT"):
                return cursor.fetchall()

        return "Success"  # Return success for non-SELECT queries
    except Exception as e:
        return f"Fail: {e}"  # Return failure message with error details
    finally:
        databaselocked = False  # Unlock the database after execution

# Process queued database actions
""""
async def processDBActions():
    global databaselocked
    while True:
        if not dbActions:
            await asyncio.sleep(1)  # Wait for new actions
            continue

        if databaselocked:
            await asyncio.sleep(0.1)  # Wait for database to be unlocked
            continue

        # Lock the database
        databaselocked = True

        # Process all actions in the queue
        with sqlite3.connect("database.db") as conn:
            cursor = conn.cursor()
            while dbActions:
                action = dbActions.pop(0)
                try:
                    action(cursor)
                except Exception as e:
                    print(f"Error processing action: {e}")

        # Unlock the database
        databaselocked = False
#
"""

# Hash and verify functions
def hash_data(data):
    if not FixedSalt:
        raise ValueError("FixedSalt has not been initialized.")
    return bcrypt.hashpw(data.encode(), FixedSalt).decode()


def verify_hash(data, hashed):
    if not FixedSalt:
        raise ValueError("FixedSalt has not been initialized.")
    return bcrypt.checkpw(data.encode(), hashed.encode())


# Add, update, delete, and authenticate functions
def add_user(userid, registeredIP, lastknownIP, username, password, ownerid, isAdmin):
    hashed_username = hash_data(username)
    hashed_password = hash_data(password)
    value = DBProcessor("""
            INSERT INTO users (userid, registeredIP, lastknownIP, username, password, ownerid, is_administrator)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (userid, registeredIP, lastknownIP, hashed_username, hashed_password, ownerid, isAdmin))
    if value == "Success":
        print(f"User {userid} added to the database.")
    return value


def update_password(userid, new_password):
    hashed_password = hash_data(new_password)
    value = DBProcessor("""
            UPDATE users
            SET password = ?
            WHERE userid = ?
        """, (hashed_password, userid))
    if value == "Success":
        print(f"Password for user {userid} updated.")
    return value


def delete_user(userid):
    value = DBProcessor("""
            DELETE FROM users
            WHERE userid = ?
        """, (userid,))
    if value == "Success":
        print(f"User {userid} deleted from the database.")
    return value


def authenticate_user(username, password):
    # Hash the username for the query
    hashed_username = hash_data(username)

    # Query the database for the user
    result = DBProcessor("""
        SELECT username, password FROM users WHERE username = ?
    """, (hashed_username,))

    # Check if the query was successful and returned a result
    if isinstance(result, list) and result:
        stored_username, stored_password = result[0]
        # Verify the stored and input data
        if verify_hash(username, stored_username) and verify_hash(password, stored_password):
            print("Authentication successful.")
            return True
    print("Authentication failed.")
    return False

