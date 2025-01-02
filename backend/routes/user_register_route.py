#   SPDX-FileCopyrightText: 2025 David Lightman
#
#   SPDX-License-Identifier: LicenseRef-CCPL

import secrets
import uuid
from aiohttp import web
from shared_libs.bridged_data import add_user
from shared_libs.config_handler import get_config_value

async def register_handler(request):
    try:
        data = await request.json()
        username = data.get("username")
        password = data.get("password")
        token = data.get("token", None)

        if not username or not password:
            return web.json_response({"success": False, "message": "Missing username or password"}, status=400)

        config = request.app["config"]
        allow_recapcha = get_config_value(config, "server.http.allow_recapcha", False)
        if allow_recapcha:
            recapcha_key = get_config_value(config, "server.http.recapcha_apikey")
            if not recapcha_key:
                return web.json_response({"success": False, "message": "reCAPTCHA is misconfigured"}, status=500)

            # Validate reCAPTCHA
            import requests
            recapcha_response = requests.post(
                "https://www.google.com/recaptcha/api/siteverify",
                data={"secret": recapcha_key, "response": token}
            )
            recapcha_result = recapcha_response.json()
            if not recapcha_result.get("success"):
                return web.json_response({"success": False, "message": "reCAPTCHA validation failed"}, status=403)

        userid = str(uuid.uuid4())
        owner_id = secrets.token_hex(8)
        peername = request.transport.get_extra_info("peername")
        ip_address = peername[0] if peername else "unknown"

        result = add_user(userid, ip_address, ip_address, username, password, owner_id, isAdmin=0)

        if result == "Success":
            return web.json_response({"success": True, "message": "User registered successfully"})
        else:
            
            return web.json_response({"success": False, "message": f"User registration failed: {result}"})

    except Exception as e:
        return web.json_response({"success": False, "message": f"Error: {str(e)}"}, status=500)


async def get_http_config(request):
    config = request.app["config"]
    try:
        return web.json_response({
            "allow_recapcha": get_config_value(config, "server.http.allow_recapcha", False),
            "recapcha_apikey": get_config_value(config, "server.http.recapcha_apikey", "")
        })
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)


def setup_routes(app):
    app.router.add_post("/bda/api/register", register_handler)
    app.router.add_get("/bda/config", get_http_config)
