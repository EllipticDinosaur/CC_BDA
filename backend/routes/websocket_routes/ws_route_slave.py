#   SPDX-FileCopyrightText: 2024 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

import asyncio
from aiohttp import web
from shared_libs.rsa import RSA
from shared_libs.end import EnD
from shared_libs.bridged_data import slaves, ws_clients, ws_slaves, verify_ownerid

rsa = RSA()
end = EnD()

# Track active ping-pong tasks
ping_pong_tasks = {}

async def ping_pong(ws, ip_port):
    """Ping-pong mechanism to keep the connection alive."""
    try:
        while True:
            print("sent ping")
            await ws.send_str("0x00")
            await asyncio.sleep(15)
    except Exception as e:
        ws.close()

def get_encryption_key_by_identifier(slaves, identifier):
    for slave in slaves:
        if slave["identifier"] == identifier:
            return slave["encryption_key"]
    return None  # Return None if no match is found


async def process_encrypted_commands(ws, identifier, cmd, owner_id):
    print(f"RX decrypted: {cmd}")
    if cmd == "0x00":
        if identifier:
            print(f"b1: getting encryptionKey {identifier}")
            ek = get_encryption_key_by_identifier(identifier)
            print(f"found encryption key: {ek}")
            if ek:
                await ws.send_str(end.encrypt("0x01|",ek))  # Pong
                print(f"ping received, sent pong: {end.encrypt("0x01|",ek)}")
        return True

    args = cmd.split("|")
    if args[0] == "2x00":  # Echo
        await ws.send_str(cmd)
    elif args[0] == "2x01":  # Initialize connection
        # Add identifier to initialized_connections
        peername = ws._req.transport.get_extra_info("peername")
        ip_port = f"{peername[0]}:{peername[1]}" if peername else "unknown"
        connection_info = {
            "connection": ip_port,
            "identifier": identifier,
            "owner_id": owner_id,
            "encryption_key": args[1],
        }

        if not verify_ownerid(owner_id):
            await ws.send_str("8x88")  # Uninstall
            print("owner not found, uninstalling")
            await ws.close()
            return False
        if connection_info not in slaves:
            slaves.append(connection_info)  # Add to the shared slaves array
            ws_slaves.append({"identifier": identifier, "owner_id": owner_id, "ws": ws})  # Add to ws_slaves
            print(f"Added connection info: {connection_info}")
            #ping_pong_tasks[ip_port] = asyncio.create_task(ping_pong(ws, ip_port))
        await ws.send_str(end.encrypt("0x01|OK", args[1]))
    elif args[0] == "5x55":  # Bridge to a client WebSocket
        owner_id = None
        for slave in slaves:
            if slave["identifier"] == identifier:
                owner_id = slave["owner_id"]
                break

        if not owner_id:
            await ws.send_str("0x03|Owner ID not found for slave")
            return

        # Find the client with the matching owner ID and permission
        target_client = None
        for client in ws_clients:
            if client["owner_id"] == owner_id and "bridged_slaves" in client and identifier in client["bridged_slaves"]:
                target_client = client
                break

        if target_client:
            client_ws = target_client["ws"]
            try:
                # Notify both WebSockets about the bridge
                await ws.send_str(f"0x01|Bridged to client {owner_id}")
                await client_ws.send_str(f"0x01|Receiving data from slave {identifier}")
                
                # Create tasks to handle bidirectional communication
                async def forward_messages(source_ws, target_ws, label):
                    async for msg in source_ws:
                        if msg.type == web.WSMsgType.TEXT:
                            # Check if the bridge is still valid
                            if not any(client["ws"] == client_ws and identifier in client.get("bridged_slaves", [])
                                       for client in ws_clients):
                                print(f"{label} bridge invalidated")
                                await source_ws.send_str("0x06|Bridge invalidated")
                                break
                            await target_ws.send_str(msg.data)
                        elif msg.type in (web.WSMsgType.CLOSE, web.WSMsgType.ERROR):
                            print(f"{label} bridge closed")
                            break

                slave_to_client = forward_messages(ws, client_ws, f"Slave {identifier} -> Client {owner_id}")
                client_to_slave = forward_messages(client_ws, ws, f"Client {owner_id} -> Slave {identifier}")

                # Run both directions concurrently
                await asyncio.gather(slave_to_client, client_to_slave)
            except Exception as e:
                print(f"Error during bridging: {e}")
                await ws.send_str("0x02|Bridge failed")
        else:
            await ws.send_str("0x03|Client not found or not accepting data")


async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    private_key, public_key = None, None
    peername = ws._req.transport.get_extra_info("peername")
    ip_port = f"{peername[0]}:{peername[1]}" if peername else "unknown"
    identifier=None
    encryption_key = None
    print(f"New connection: {ip_port}")

    try:
        async for msg in ws:
            if msg.type == web.WSMsgType.TEXT:
                print(msg.data)
                if msg.data == "0x00":  # Ping
                    await ws.send_str("0x01|")  # Pong
                elif msg.data == "0x01": #pong
                    print("ping received")
                elif msg.data.startswith("1x00|"):  # Init, respond with public key
                    private_key, public_key = rsa.generate_keys()
                    await ws.send_str(f"1x01|{public_key[0]},{public_key[1]}")
                elif msg.data.startswith("1x01|"):  #Command executor
                    args = msg.data.split("|")
                    if len(args) >= 4:
                        identifier = args[1]
                        owner_id = args[2]
                        encrypted_data = args[3]
                        try:
                            decrypted_data = rsa.decrypt(private_key, encrypted_data)
                            await process_encrypted_commands(ws, identifier, decrypted_data, owner_id)
                        except Exception as e:
                            print(f"Decryption failed: {e}")
                            await ws.send_str("ERROR|Decryption failed")
                elif msg.type == web.WSMsgType.ERROR:
                    print(f"WebSocket connection closed with exception {ws.exception()}")
                else:
                    if encryption_key == None:
                        if identifier:
                            encryption_key = get_encryption_key_by_identifier(identifier)
                    decrypted_data = end.decrypt(msg.data, encryption_key)
                    await process_encrypted_commands(ws, identifier, decrypted_data, owner_id)
    except Exception as e:
        await ws.send_str(f"9x99|Internal Server Error|{e}") 
        print(f"SHIT SLAVE ERROR: {e}")
    finally:
        print(f"WebSocket disconnected: {ip_port}")
        slaves[:] = [conn for conn in slaves if conn["connection"] != ip_port]
        ws_slaves[:] = [slave for slave in ws_slaves if slave["ws"] != ws]
        if ip_port in ping_pong_tasks:
            ping_pong_tasks[ip_port].cancel()  # Cancel the ping-pong task
            del ping_pong_tasks[ip_port]

    return ws


def setup_routes_slave(app):
    app.router.add_get("/ws/slave", websocket_handler)
