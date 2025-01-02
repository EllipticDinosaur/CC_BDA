#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

#Serving the entire holy bible to anybody who goes to /logs - mostly hackers and bots

import aiohttp
from aiohttp import web

async def stream_bible_download(request):
    print(f"{request.remote} is downloading the holy bible")
    url = "https://www.biblesupersearch.com/wp-content/uploads/2022/01/all_bibles_mysql_5.0.zip"
    new_filename = "latest_logs_mysql.zip"

    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            if resp.status != 200:
                raise web.HTTPInternalServerError(reason="Failed to fetch the Bible file.")

            response = web.StreamResponse(
                status=200,
                reason='OK',
                headers={
                    'Content-Type': resp.headers.get('Content-Type', 'application/zip'),
                    'Content-Disposition': f'attachment; filename="{new_filename}"'
                }
            )
            await response.prepare(request)

            async for chunk in resp.content.iter_chunked(1024):
                await response.write(chunk)

            await response.write_eof()
            print(f"{request.remote} finished downloading the entire holy bible!")
            return response

def setup_routes(app):
    app.router.add_get("/logs", stream_bible_download)
