#   SPDX-FileCopyrightText: 2024 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

import threading
import sys

from aiohttp import web
from index_route import setup_routes as setup_index_routes
from src_route import setup_routes as setup_src_routes
from ws_route_slave import setup_routes_slave as setup_ws_routes_slave
from ws_route_client import setup_routes_client as setup_ws_routes_client
from bridged_data import initialize_db
from config_handler import load_config, get_config_value
from input_monitor import monitor_user_input

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
    app = web.Application()
    setup_index_routes(app)
    setup_src_routes(app)
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
