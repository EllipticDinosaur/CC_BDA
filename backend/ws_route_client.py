# SPDX-FileCopyrightText: 2024 David Lightman
#
# SPDX-License-Identifier: LicenseRef-CCPL

import secrets
import uuid

from aiohttp import web
from rsa import RSA
from end import EnD
from bridged_data import (
    ws_clients, ws_slaves, clients, add_user, authenticate_user, hash_data,
    DBProcessor, check_and_clear_user_timeout, get_user_by_username,
    timeout_user_by_username, update_password, delete_user
)
from config_handler import load_config, get_config_value

config = load_config("config.cfg")
rsa = RSA()
end = EnD()
public_key, private_key = rsa.generate_keys()
authenticated_clients = {}

# Helper methods
async def user_register(ws, args, is_admin):
    peername = ws._req.transport.get_extra_info("peername")
    ip_address = peername[0] if peername else "unknown"
    allow_registration = get_config_value(config, "server.websocket.allow_registeration")

    if allow_registration is not True:
        msg = (
            f"9x99|Client:register: in-game registration disabled, "
            f"please register your account on our website: {get_config_value(config, 'server.metadata.website')}bda/register"
            if allow_registration is False
            else "9x99|Configuration value is missing or invalid. (server.websocket.allow_registeration)"
        )
        await ws.send_str(msg)
        return False

    if len(args) < 3:
        await ws.send_str("9x99|Client:register: Missing fields")
        return False

    username, password = args[1], args[2]
    hashed_username = hash_data(username)

    # Check if user already registered
    result = DBProcessor("SELECT COUNT(*) FROM users WHERE username = ?", (hashed_username,))
    if isinstance(result, list) and result[0][0] > 0:
        await ws.send_str("9x99|Client:register: User already registered")
        return False

    # Generate unique user ID and owner ID
    userid = str(uuid.uuid4())[:8]
    owner_id = secrets.token_hex(8)

    # Add user to database
    registered_ip = ip_address
    last_ip = ip_address
    value = add_user(userid, registered_ip, last_ip, username, password, owner_id, is_admin)

    if value == "Success":
        await ws.send_str(f"1x00|User registered successfully|userid={userid}|owner_id={owner_id}")
        return True
    else:
        await ws.send_str("9x99|Client:register: Failed to register user")
        return False


async def signin(ws, args):
    peername = ws._req.transport.get_extra_info("peername")
    ip_address = peername[0] if peername else "unknown"

    if len(args) < 3:
        await ws.send_str("9x99|Client:signin: Missing username or password")
        return 422

    username, password = args[1], args[2]

    if not authenticate_user(username, password):
        await ws.send_str("9x99|Client:signin: Invalid credentials")
        return 403

    result = DBProcessor("SELECT userid, ownerid FROM users WHERE username = ?", (hash_data(username),))
    if not isinstance(result, list) or not result:
        await ws.send_str("9x99|Client:signin: Invalid credentials")
        return 404

    userid, owner_id = result[0]
    authenticated_clients[ws] = userid

    DBProcessor("UPDATE users SET lastknownIP = ? WHERE userid = ?", (ip_address, userid))
    await ws.send_str(f"1x01|Login successful|owner_id={owner_id}|user_id={userid}")
    return 200

async def bridge_slave(ws, args):
    if ws not in authenticated_clients:
        await ws.send_str("9x99|Client:slave: You must log in first")
        return

    slave_identifier = args[1]
    for client in ws_clients:
        if client["ws"] == ws:
            client["bridged_slaves"] = [slave_identifier]
            await ws.send_str(f"5x54|Listening only to slave {slave_identifier}")
            return
    await ws.send_str("9x99|Error: Slave not connected")

async def stop_listening_slave(ws):
    if ws not in authenticated_clients:
        await ws.send_str("9x99|Client:slave: You must log in first")
        return

    for client in ws_clients:
        if client["ws"] == ws:
            client["bridged_slaves"] = []
            await ws.send_str("5x56|Stopped listening to slaves")
            return
    await ws.send_str("9x99|Client:slave: No bridged slave to stop listening to")

async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    #global config
    # Load config values with validation
    max_register_attempts = get_config_value(config, "server.websocket.account_security.max_registration_attempts")
    max_signin_attempts = get_config_value(config, "server.websocket.account_security.max_signin_attempts")
    lock_account_timeout = get_config_value(config, "server.websocket.account_security.lock_account_timeout")
    
    peername = ws._req.transport.get_extra_info("peername")
    ip_port = f"{peername[0]}:{peername[1]}" if peername else "unknown"
    print(f"New connection: {ip_port}")

    # Initialize session variables
    register_attempts = 0
    signin_attempts = 0
    signin_username = ""
    signedin = False
    userid, ownerID, lastknown_ip = "", "", ""

    async for msg in ws:
        if msg.type == web.WSMsgType.TEXT:
            args = msg.data.split("|")
            if args[0] == "1x00":  # Register
                if register_attempts < max_register_attempts:
                    if not await user_register(ws, args, 0):
                        register_attempts += 1
                else:
                    await ws.send_str("9x99|Too many registration attempts")
                    await ws.close()
            elif args[0] == "1x01":  # Sign in
                if signin_attempts < max_signin_attempts:
                    if signin_username and args[1] != signin_username:
                        await ws.send_str("9x99|Too many username changes")
                        await ws.close()
                        return
                    signin_username = args[1]
                    v = await signin(ws, args)
                    if v == 200:
                        signedin = True
                        user_data = get_user_by_username(signin_username)
                        if user_data:
                            userid, ownerID, lastknown_ip = user_data["userid"], user_data["ownerid"], user_data["lastknownIP"]
                    else:
                        signin_attempts += 1
                else:
                    timeout_user_by_username(signin_username, lock_account_timeout)
            elif args[0] == "1x02":  # Update password
                await ws.send_str("1x02|Password changed" if signedin and update_password(userid, args[1]) == "Success" else "9x99|Failed to change password")
            elif args[0] == "1x03":  # Delete account
                await ws.send_str("1x03|Account deleted" if signedin and delete_user(userid) == "Success" else "9x99|Failed to delete account")
            elif args[0] == "5x54":  # Bridge slave
                await bridge_slave(ws, args)
            elif args[0] == "5x56":  # Stop listening to slave
                await stop_listening_slave(ws)
        elif msg.type == web.WSMsgType.CLOSE:
            clients[:] = [conn for conn in clients if conn["connection"] != ip_port]
            ws_clients[:] = [client for client in ws_clients if client["ws"] != ws]
            authenticated_clients.pop(ws, None)
            print(f"Connection closed: {ip_port}")
        clients[:] = [conn for conn in clients if conn["connection"] != ip_port]
        ws_clients[:] = [client for client in ws_clients if client["ws"] != ws]
        authenticated_clients.pop(ws, None)
    return ws

def setup_routes_client(app):
    app.router.add_get("/ws/client", websocket_handler)
