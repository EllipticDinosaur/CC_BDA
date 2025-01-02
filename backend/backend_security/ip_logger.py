#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL
from aiohttp import web

async def logger_handler(request):
    client_ip = request.remote
    print(f"/security/failure: Redirect triggered by client IP: {client_ip}")

    # Redirect to the target URL
    return web.HTTPFound(location="https://grabify.link/W7OHWG.gif")

def setup_routes(app):
    app.router.add_get("/security/failure", logger_handler)
