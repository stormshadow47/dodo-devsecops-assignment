import os
import sqlite3
import uuid

from flask import Flask, request, jsonify

app = Flask(__name__)

DATABASE_PATH = os.environ.get("DATABASE_PATH")
if not DATABASE_PATH:
    raise ValueError("DATABASE_PATH environment variable is required")


def init_db():
    connection = sqlite3.connect(DATABASE_PATH)
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            token TEXT NOT NULL,
            last4 TEXT,
            amount REAL,
            currency TEXT,
            status TEXT,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    connection.commit()
    connection.close()


init_db()


def get_db_connection():
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


@app.route("/health")
def health():
    return jsonify(status="ok")


@app.route("/transactions", methods=["GET"])
def transactions():
    connection = get_db_connection()
    rows = connection.execute(
        """
        SELECT
            id,
            token,
            last4,
            amount,
            currency,
            status,
            created_at
        FROM transactions
        ORDER BY created_at DESC
        """
    ).fetchall()
    connection.close()

    return jsonify([dict(row) for row in rows])


@app.route("/transactions", methods=["POST"])
def create_transaction():
    payload = request.get_json(silent=True) or {}

    token = payload.get("token")
    if not token:
        return jsonify(error="token is required"), 400

    transaction_id = payload.get("id") or str(uuid.uuid4())

    record = {
        "id": transaction_id,
        "token": token,
        "last4": payload.get("last4"),
        "amount": payload.get("amount"),
        "currency": payload.get("currency"),
        "status": payload.get("status"),
    }

    connection = get_db_connection()

    connection.execute(
        """
        INSERT INTO transactions
        (id, token, last4, amount, currency, status)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            record["id"],
            record["token"],
            record["last4"],
            record["amount"],
            record["currency"],
            record["status"],
        ),
    )

    connection.commit()
    connection.close()

    return jsonify(record), 201


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)