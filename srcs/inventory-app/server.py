from waitress import serve
from app import create_app

import os


PORT = os.getenv("APP_PORT", "8080")

app = create_app()
print(f"Listening on port {PORT}...")

serve(app, listen=f"*:{PORT}")
