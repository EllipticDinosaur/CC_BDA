#   SPDX-FileCopyrightText: 2024 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

import threading
import sys
import logging

from aiohttp import web
from backend_security.ip_logger import setup_routes as setup_iplogger_route
from backend_security.http_error_handling import error_handling_middleware
from routes.index_route import setup_routes as setup_index_routes
from routes.src_route import setup_routes as setup_src_routes
from routes.user_register_route import setup_routes as setup_register_routes
from routes.websocket_routes.ws_route_slave import setup_routes_slave as setup_ws_routes_slave
from routes.websocket_routes.ws_route_client import setup_routes_client as setup_ws_routes_client
from shared_libs.bridged_data import initialize_db
from shared_libs.config_handler import load_config, get_config_value
from shell.input_monitor import monitor_user_input

logging.basicConfig(level=logging.WARNING)
logging.getLogger("aiohttp.access").setLevel(logging.CRITICAL)

CONFIG = ""
# Load config
try:
    CONFIG = load_config(
        file_path="config.cfg",
        github_url="https://raw.githubusercontent.com/EllipticDinosaur/CC_BDA/main/backend/template.cfg"
    )
except Exception as e:
    print(f"Failed to load config: {e}")
    sys.exit(1)


async def create_app():
    initialize_db(CONFIG)
    app = web.Application(middlewares=[error_handling_middleware])
    setup_iplogger_route(app)
    setup_index_routes(app)
    setup_src_routes(app)
    app["config"] = CONFIG
    if (get_config_value(CONFIG, "server.http.forms.registration")):
        setup_register_routes(app)
        app.router.add_get("/bda/register", lambda request: web.FileResponse("routes/frontend/register.html"))
    setup_ws_routes_slave(app)
    setup_ws_routes_client(app)
    return app


if __name__ == '__main__':
    app = create_app()

    # Start the input monitor in a separate thread
    input_thread = threading.Thread(target=monitor_user_input, daemon=True)
    input_thread.start()

    # Run the web application
    web.run_app(app, port=get_config_value(CONFIG, "server.port"))
