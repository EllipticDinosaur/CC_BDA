#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL
import random

from aiohttp import web

loggers = ["https://www.youtube.com/watch?v=0UghlW1TsMA","https://www.youtube.com/watch?v=5YBzYDarSi0","https://www.youtube.com/watch?v=md-3lzwqeek","https://www.youtube.com/watch?v=1ujDD2LpSRg","https://www.youtube.com/watch?v=TQUsLAAZuhU", "https://www.youtube.com/watch?v=Rn2cf_wJ4f4"]
# Please do not click on the ip logger link as it wil log your ip for my personal use.. --All links have been removed--
# Some modules have been left out for security reasons.
# It is wrong to try to set up an automatic honey pot that attacks the attackers, as funny as it is, you probably shouldn't do it.
# So enjoy a movie or something instead.

async def logger_handler(request):
    client_ip = request.remote
    print(f"/security/failure: Redirect triggered by client IP: {client_ip}")

    # Removed the iplogger code for privacy and security reasons.
    return web.HTTPFound(location=random.choice(loggers))

def setup_routes(app):
    app.router.add_get("/security/failure", logger_handler)
