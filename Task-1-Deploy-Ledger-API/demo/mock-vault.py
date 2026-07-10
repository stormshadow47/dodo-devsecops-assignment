"""
Local PCI tokenization vault mock for demo.

"""

import hashlib
import os
import re

from flask import Flask, jsonify, request

app = Flask(__name__)

VAULT_AUTH_KEY = os.environ.get("VAULT_AUTH_KEY")
PAN_PATTERN = re.compile(r"^\d{16}$")
TOKENS = {}


def require_auth():
    auth = request.headers.get("Authorization", "")
    if auth != f"Bearer {VAULT_AUTH_KEY}":
        return jsonify(error="unauthorized"), 401
    return None


def looks_like_pan(value):
    return isinstance(value, str) and bool(PAN_PATTERN.match(value))


@app.route("/health")
def health():
    return jsonify(status="ok", service="mock-pci-vault")


@app.route("/v1/tokens/tokenize", methods=["POST"])
def tokenize():
    unauthorized = require_auth()
    if unauthorized:
        return unauthorized

    payload = request.get_json(silent=True) or {}
    pan = payload.get("pan")
    if not pan or not looks_like_pan(str(pan)):
        return jsonify(error="valid pan is required"), 400

    pan = str(pan)
    token = "tok_" + hashlib.sha256(pan.encode()).hexdigest()[:16]
    TOKENS[token] = {"token": token, "last4": pan[-4:]}
    return jsonify(TOKENS[token])


@app.route("/v1/tokens/verify", methods=["POST"])
def verify():
    unauthorized = require_auth()
    if unauthorized:
        return unauthorized

    payload = request.get_json(silent=True) or {}
    token = payload.get("token")
    if not token:
        return jsonify(error="token is required"), 400

    record = TOKENS.get(token)
    if not record:
        return jsonify(error="unknown token"), 404

    return jsonify(record)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8092)
