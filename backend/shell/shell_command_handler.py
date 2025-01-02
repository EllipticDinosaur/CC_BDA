#   SPDX-FileCopyrightText: 2024 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL
import uuid, secrets
from shared_libs.bridged_data import DBProcessor,hash_data, get_user_by_username, add_user, delete_user_by_username

def user_whois(username):
    user = get_user_by_username(username)
    if (user==None):
        print("User not found")
        return False
    print(f" whois: {username}")
    print(f"    userid: {user[1]}")
    print(f"    registeredIP: {user[2]}")
    print(f"    lastknownIP: {user[3]}")
    print(f"    password_hash: {user[5]}")
    print(f"    ownerid: {user[6]}")
    print(f"    timedout: {user[7]}")
    print(f"    is admin: {user[8]}")

def user_create(username, password, isadmin):
    if not (isinstance(username, str) and isinstance(password, str) and isinstance(isadmin, int)):
        print("An argument was inncorrect, looking for: string, string, integer")
        return False
    isadmin = str(isadmin)
    print(f"username: {username} password: {password} isadmin {isadmin}")
    print(add_user(str(uuid.uuid4()), "127.0.0.1","127.0.0.1",username,password,secrets.token_hex(16),isadmin))

def user_deletion(username):
    if not isinstance(username, str):
        print("An argument was inncorrect, looking for: string")
        return False
    delete_user_by_username(username)