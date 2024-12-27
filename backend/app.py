from aiohttp import web
from index_route import setup_routes as setup_index_routes
from src_route import setup_routes as setup_src_routes
from ws_route import setup_routes as setup_ws_routes

def create_app():
    app = web.Application()
    setup_index_routes(app)
    setup_src_routes(app)
    setup_ws_routes(app)
    return app

if __name__ == '__main__':
    app = create_app()
    web.run_app(app, port=80)
