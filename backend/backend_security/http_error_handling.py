#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

from aiohttp.web_middlewares import middleware
from aiohttp import web
from shared_libs.config_handler import load_config, get_config_value
config = load_config("config.cfg")

@middleware
async def error_handling_middleware(request, handler):
    client_ip = request.remote
    try:
        response = await handler(request)  # Process the request
        return response
    except web.HTTPException as ex:
        # Customize HTTP error responses
        
        if ex.status == 404:
            return web.json_response(
                {"error": ex.reason, "status": ex.status},
                status=ex.status
            )
        else:
            print(f"{client_ip} attempted to exploit the webserver, err code: {ex.status}")
            return web.json_response(
                {"error": ex.reason, "status": ex.status},
                status=1337
            )
    except Exception as e:
        # Catch-all for unhandled exceptions
        print(f"{client_ip} attempted to exploit the webserver")
        return web.json_response(
            {"error": "Internal Server Error", "privacy details": f"By attempting to exploit this website you have agreed to a swift retaliation! Thank you for your ip address {client_ip}, payloads will be bound shortly, hold tight!   This was by mistake? {get_config_value(config, "server.metadata.website")}/security/failure"},
            status=1337
        )
        
