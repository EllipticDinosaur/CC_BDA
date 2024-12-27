from aiohttp import web
from rsa import RSA
rsa = RSA()
public_key, private_key = rsa.generate_keys()

initalized_connections=[]

async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)

    async for msg in ws:
        if msg.type == web.WSMsgType.TEXT:
            if msg.data == "0x00": #ping
                await ws.send_str("0x01") #pong
            elif msg.data == "1x00": #init
                await ws.send_str("1x01|{public_key}") #Respose with public key
            elif msg.data.startswith("1x01|"):  #command executor
                _, encrypted_data = msg.data.split("|", 1)
                decrypted_data = rsa.decrypt(private_key, encrypted_data)
                process_encrypted_commands(decrypted_data)
            elif msg.type == web.WSMsgType.ERROR:
                print(f"WebSocket connection closed with exception {ws.exception()}")
    return ws

def process_encrypted_commands(cmd):
    if (cmd=="2x00"): #Echo
        print("lel")

def setup_routes(app):
    app.router.add_get("/ws", websocket_handler)
