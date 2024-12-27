from aiohttp import web

async def index_handler(request):
    return web.Response(text="Nothing here yet, come back another time. This is just a dump box for computercraft and opencomputers projects.\nAny attempts to exploit the website may result in automated retaliation.")

def setup_routes(app):
    app.router.add_get("/", index_handler)
