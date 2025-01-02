#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

from aiohttp import web

async def register_handler(request):
    return web.Response(text="Nothing here yet, come back another time. This is just a dump box for computercraft and opencomputers projects.\nAny attempts to exploit the website may result in automated retaliation.")

def setup_routes(app):
    app.router.add_get("/bda/register", register_handler)
