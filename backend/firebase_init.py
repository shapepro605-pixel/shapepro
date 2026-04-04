"""
Firebase Admin SDK initialization for ShapePro backend.
Initializes once at app startup using service account credentials.
"""
import os
import json
import firebase_admin
from firebase_admin import credentials

_firebase_app = None


def init_firebase():
    """Initialize Firebase Admin SDK from environment variable."""
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    creds_json = os.getenv('FIREBASE_CREDENTIALS_JSON', '')

    if not creds_json:
        print("[FIREBASE] ⚠️ FIREBASE_CREDENTIALS_JSON not set. Phone verification will use fallback mode.")
        return None

    try:
        creds_dict = json.loads(creds_json)
        cred = credentials.Certificate(creds_dict)
        _firebase_app = firebase_admin.initialize_app(cred)
        print("[FIREBASE] ✅ Firebase Admin SDK initialized successfully.")
        return _firebase_app
    except Exception as e:
        print(f"[FIREBASE] ❌ Failed to initialize: {e}")
        return None


def is_firebase_initialized():
    """Check if Firebase Admin SDK is ready."""
    return _firebase_app is not None
