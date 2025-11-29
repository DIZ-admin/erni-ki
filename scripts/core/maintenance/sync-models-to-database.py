#!/usr/bin/env python3
"""
ERNI-KI OpenWebUI Model Synchronization Script
Sync models from Ollama and LiteLLM into OpenWebUI database
"""

import json
import os
import sys
import uuid
from datetime import datetime

import psycopg2  # type: ignore[import-untyped]
import requests  # type: ignore[import-untyped]


def read_secret(secret_name: str) -> str | None:
    secret_paths = [
        f"/run/secrets/{secret_name}",
        os.path.join(os.path.dirname(__file__), "..", "..", "..", "secrets", f"{secret_name}.txt"),
    ]
    for path in secret_paths:
        if os.path.isfile(path):
            with open(path, encoding="utf-8") as f:
                return f.read().strip()
    return None


def get_database_connection():
    """Get PostgreSQL connection"""
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        db_user = os.environ.get("OPENWEBUI_DB_USER", "openwebui_user")
        db_name = os.environ.get("OPENWEBUI_DB_NAME", "openwebui")
        db_host = os.environ.get("OPENWEBUI_DB_HOST", "db")
        db_port = os.environ.get("OPENWEBUI_DB_PORT", "5432")
        password = read_secret("postgres_password")
        if not password:
            print("❌ DATABASE_URL is not set and postgres_password secret is missing")
            return None
        database_url = f"postgresql://{db_user}:{password}@{db_host}:{db_port}/{db_name}"

    try:
        return psycopg2.connect(database_url)
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        return None


def get_ollama_models():
    """Fetch models from Ollama"""
    try:
        response = requests.get("http://ollama:11434/api/tags", timeout=10)
        if response.status_code == 200:
            data = response.json()
            models = []
            for model in data.get("models", []):
                models.append(
                    {
                        "id": model["name"],
                        "name": model["name"],
                        "provider": "ollama",
                        "base_model_id": model["name"],
                        "size": model.get("size", 0),
                        "details": model.get("details", {}),
                        "modified_at": model.get("modified_at", datetime.now().isoformat()),
                    }
                )
            return models
        else:
            print(f"⚠️ Ollama API returned status: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Failed to fetch Ollama models: {e}")
        return []


def get_litellm_models():
    """Fetch models from LiteLLM"""
    api_key = os.environ.get("LITELLM_API_KEY") or read_secret("litellm_api_key")
    if not api_key:
        print("❌ LITELLM_API_KEY not set (env or secret)")
        return []

    try:
        headers = {"Authorization": f"Bearer {api_key}"}
        response = requests.get("http://litellm:4000/v1/models", headers=headers, timeout=10)
        if response.status_code == 200:
            data = response.json()
            models = []
            for model in data.get("data", []):
                models.append(
                    {
                        "id": model["id"],
                        "name": model["id"],
                        "provider": "litellm",
                        "base_model_id": model["id"],
                        "size": 0,  # LiteLLM does not provide size
                        "details": {"object": model.get("object", "model")},
                        "modified_at": datetime.now().isoformat(),
                    }
                )
            return models
        else:
            print(f"⚠️ LiteLLM API returned status: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Failed to fetch LiteLLM models: {e}")
        return []


def sync_models_to_database(models):
    """Sync models into database"""
    conn = get_database_connection()
    if not conn:
        return False

    try:
        cursor = conn.cursor()

        # Existing models
        cursor.execute("SELECT id, base_model_id FROM model")
        existing_models = {row[1]: row[0] for row in cursor.fetchall()}

        admin_user_id = os.environ.get("OPENWEBUI_ADMIN_USER_ID") or read_secret(
            "openwebui_admin_user_id"
        )
        if not admin_user_id:
            raise ValueError("OPENWEBUI_ADMIN_USER_ID must be configured via env or secret")

        synced_count = 0
        for model in models:
            model_id = model["base_model_id"]

            if model_id not in existing_models:
                # Insert new model
                new_uuid = str(uuid.uuid4())
                params = {
                    "provider": model["provider"],
                    "size": model["size"],
                    "details": model["details"],
                }

                cursor.execute(
                    """
                    INSERT INTO model (
                        id,
                        user_id,
                        base_model_id,
                        name,
                        params,
                        created_at,
                        updated_at
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                    (
                        new_uuid,
                        admin_user_id,
                        model_id,
                        model["name"],
                        json.dumps(params),
                        datetime.now(),
                        datetime.now(),
                    ),
                )
                synced_count += 1
                print(f"✅ Added model: {model['name']} ({model['provider']})")
            else:
                # Update existing
                params = {
                    "provider": model["provider"],
                    "size": model["size"],
                    "details": model["details"],
                }

                cursor.execute(
                    """
                    UPDATE model
                    SET params = %s, updated_at = %s
                    WHERE base_model_id = %s
                """,
                    (json.dumps(params), datetime.now(), model_id),
                )
                print(f"🔄 Updated model: {model['name']} ({model['provider']})")

        conn.commit()
        cursor.close()
        conn.close()

        print(f"\n📊 Sync complete: {synced_count} new models added")
        return True

    except Exception as e:
        print(f"❌ Database sync error: {e}")
        if conn:
            conn.rollback()
            conn.close()
        return False


def main():
    """Entry point"""
    print("🔄 ERNI-KI Model Synchronization")
    print("=" * 40)

    # Fetch models from providers
    print("📡 Fetching models from Ollama...")
    ollama_models = get_ollama_models()
    print(f"   Found: {len(ollama_models)} models")

    print("📡 Fetching models from LiteLLM...")
    litellm_models = get_litellm_models()
    print(f"   Found: {len(litellm_models)} models")

    # Merge all models
    all_models = ollama_models + litellm_models
    print(f"\n📋 Total models to sync: {len(all_models)}")

    if not all_models:
        print("⚠️ No models found. Check provider connectivity.")
        return 1

    # Sync to database
    print("\n💾 Syncing with database...")
    if sync_models_to_database(all_models):
        print("✅ Sync completed successfully!")
        return 0
    else:
        print("❌ Sync failed!")
        return 1


if __name__ == "__main__":
    sys.exit(main())
