from app.consume_queue import consume_and_store_order
from app.orders import Base

from flask import Flask, jsonify
from sqlalchemy import create_engine
from threading import Thread
from waitress import serve

import os


def create_billing_app(engine):
    app = Flask(__name__)

    @app.route("/health", methods=["GET"])
    def health():
        return jsonify({"status": "ok"}), 200

    return app


if __name__ == "__main__":
    BILLING_DB_USER = os.getenv("BILLING_DB_USER")
    BILLING_DB_PASSWORD = os.getenv("BILLING_DB_PASSWORD")
    BILLING_DB_NAME = os.getenv("BILLING_DB_NAME")
    BILLING_DB_HOST = os.getenv("BILLING_DB_HOST", "localhost")
    APP_PORT = os.getenv("APP_PORT", "8080")

    DB_URI = (
        "postgresql://"
        f'{BILLING_DB_USER}:{BILLING_DB_PASSWORD}'
        f'@{BILLING_DB_HOST}:5432/{BILLING_DB_NAME}'
    )

    engine = create_engine(DB_URI)
    Base.metadata.create_all(engine)

    billing_app = create_billing_app(engine)
    consumer_thread = Thread(
        target=consume_and_store_order,
        args=(engine,),
        daemon=True
    )
    consumer_thread.start()

    print(f"Billing app listening on port {APP_PORT}...")
    serve(billing_app, listen=f"*:{APP_PORT}")
