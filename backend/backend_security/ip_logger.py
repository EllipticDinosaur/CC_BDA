#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL
from aiohttp import web


# Please do not click on the ip logger link as it wil log your ip for my personal use..
# Some modules have been left out for security reasons.
# It is wrong to try to set up an automatic honey pot that attacks the attackers, as funny as it is, you probably shouldn't do it.

async def logger_handler(request):
    client_ip = request.remote
    print(f"/security/failure: Redirect triggered by client IP: {client_ip}")

    # Removed the iplogger code for privacy and security reasons.
    return web.HTTPFound(location="https://www.youtube.com/watch?v=oL-goo7Cy7k")

def setup_routes(app):
    app.router.add_get("/security/failure", logger_handler)
