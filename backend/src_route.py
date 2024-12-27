import aiohttp
from aiohttp import web
from mimetypes import guess_type

async def fetch_and_serve_file(request):
    # Capture the full path (path + filename)
    full_path = request.match_info.get('full_path', '')
    if not full_path:
        raise web.HTTPBadRequest(text="File path is required.")

    github_owner = "EllipticDinosaur"
    github_repo = "CC_BDA"
    github_branch = "main"
    raw_url = f"https://raw.githubusercontent.com/{github_owner}/{github_repo}/{github_branch}/stub/{full_path}"

    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(raw_url) as response:
                if response.status == 200:
                    mime_type, _ = guess_type(full_path)
                    if mime_type is None:
                        mime_type = 'text/plain'
                    file_data = await response.read()
                    return web.Response(body=file_data, content_type=mime_type)
                else:
                    raise web.HTTPNotFound(text="File not found on GitHub")
    except aiohttp.ClientError as e:
        raise web.HTTPInternalServerError(text=f"Error fetching file: {str(e)}")

def setup_routes(app):
    app.router.add_get("/src/{full_path:.+}", fetch_and_serve_file)
