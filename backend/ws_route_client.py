import secrets
import uuid

from aiohttp import web
from rsa import RSA
from end import EnD
from bridged_data import ws_clients, clients, add_user, authenticate_user, hash_data, DBProcessor

rsa = RSA()
end = EnD()
public_key, private_key = rsa.generate_keys()

# Track authenticated WebSocket connections
authenticated_clients = {}

async def process_encrypted_commands(ws, cmd):
    args = cmd.split("|")
    peername = ws._req.transport.get_extra_info("peername")
    ip_address = peername[0] if peername else "unknown"

    if args[0] == "1x00":  # Echo
        await ws.send_str(cmd)

    elif args[0] == "2x02":  # Register a new user
        if len(args) >= 3:  # Ensure we have enough fields for registration
            username = args[1]
            password = args[2]

            # Check if the user is already registered
            hashed_username = hash_data(username)
            result = DBProcessor("""
                SELECT COUNT(*) FROM users WHERE username = ?
            """, (hashed_username,))

            if isinstance(result, list) and result[0][0] > 0:
                await ws.send_str("0x02|Error: User already registered")
                return

            # Generate a unique userid and ownerID
            userid = str(uuid.UUID()) # Generates an 8-character unique string
            owner_id = secrets.token_hex(8)  # Generates a 16-character unique string

            # Use IP address as registered_ip and last_ip during registration
            registered_ip = ip_address
            last_ip = ip_address

            # Add user to the database
            value = add_user(userid, registered_ip, last_ip, username, password, owner_id)

            if value == "Success":
                await ws.send_str(f"0x02|User registered successfully|userid={userid}|owner_id={owner_id}")
            else:
                await ws.send_str(f"0x02|Error: {value}")
        else:
            await ws.send_str("0x02|Error: Missing fields")

    elif args[0] == "2x03":  # Login command
        if len(args) >= 3:  # Ensure username and password are provided
            username = args[1]
            password = args[2]

            # Authenticate the user
            if authenticate_user(username, password):
                # Fetch additional user details
                result = DBProcessor("""
                    SELECT userid, ownerid FROM users WHERE username = ?
                """, (hash_data(username),))

                if isinstance(result, list) and result:
                    userid, owner_id = result[0]
                    authenticated_clients[ws] = owner_id
                    
                    # Update lastknown_ip in the database to the current IP address
                    DBProcessor("""
                        UPDATE users SET lastknownIP = ? WHERE userid = ?
                    """, (ip_address, userid))

                    await ws.send_str(f"0x03|Login successful|owner_id={owner_id}")
                else:
                    await ws.send_str("0x03|Login failed: User not found")
            else:
                await ws.send_str("0x03|Login failed: Invalid credentials")
        else:
            await ws.send_str("0x03|Error: Missing username or password")

    elif args[0] == "5x54":  # Allow accepting data from a specific slave
        # Check if the client is authenticated
        if ws not in authenticated_clients:
            await ws.send_str("0x05|Error: You must log in first")
            return
        slave_identifier = args[1]

        # Update the client's entry in ws_clients to allow only the latest slave
        for client in ws_clients:
            if client["ws"] == ws:
                # Ensure only the latest slave is set
                client["bridged_slaves"] = [slave_identifier]
                await ws.send_str(f"0x01|Listening only to slave {slave_identifier}")
                break
        else:
            await ws.send_str("0x04|Error: Slave not recognized")


async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)

    # Track the WebSocket's connection info
    peername = ws._req.transport.get_extra_info("peername")
    ip_port = f"{peername[0]}:{peername[1]}" if peername else "unknown"
    print(f"New connection: {ip_port}")

    async for msg in ws:
        if msg.type == web.WSMsgType.TEXT:
            print(msg.data)
            if msg.data == "0x00":  # Ping
                await ws.send_str("0x01")  # Pong
            elif msg.data.startswith("1x00|"):  # Init, respond with public key
                await ws.send_str(f"1x01|{public_key[0]},{public_key[1]}")
            else:
                await process_encrypted_commands(ws, msg.data)
        elif msg.type == web.WSMsgType.CLOSE:
            # Handle WebSocket closure
            print(f"WebSocket disconnected: {ip_port}")
            clients[:] = [
                conn for conn in clients if conn["connection"] != ip_port
            ]
            ws_clients[:] = [client for client in ws_clients if client["ws"] != ws]
            if ws in authenticated_clients:
                del authenticated_clients[ws]

    print(f"Connection closed: {ip_port}")
    clients[:] = [
        conn for conn in clients if conn["connection"] != ip_port
    ]
    ws_clients[:] = [client for client in ws_clients if client["ws"] != ws]
    if ws in authenticated_clients:
        del authenticated_clients[ws]
    return ws


def setup_routes_client(app):
    app.router.add_get("/ws/client", websocket_handler)
