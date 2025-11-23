#!/usr/bin/env python3
"""
ERNI-KI OpenWebUI Model Synchronization Script
Sync models from Ollama and LiteLLM into OpenWebUI database
"""

import os
import sys
import json
import requests
import psycopg2
from datetime import datetime
import uuid

def get_database_connection():
    """Get PostgreSQL connection"""
    try:
        database_url = os.environ.get('DATABASE_URL',
            'postgresql://openwebui_user:OW_secure_pass_2025!@db:5432/openwebui')
        conn = psycopg2.connect(database_url)
        return conn
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        return None

def get_ollama_models():
    """Fetch models from Ollama"""
    try:
        response = requests.get('http://ollama:11434/api/tags', timeout=10)
        if response.status_code == 200:
            data = response.json()
            models = []
            for model in data.get('models', []):
                models.append({
                    'id': model['name'],
                    'name': model['name'],
                    'provider': 'ollama',
                    'base_model_id': model['name'],
                    'size': model.get('size', 0),
                    'details': model.get('details', {}),
                    'modified_at': model.get('modified_at', datetime.now().isoformat())
                })
            return models
        else:
            print(f"⚠️ Ollama API returned status: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Failed to fetch Ollama models: {e}")
        return []

def get_litellm_models():
    """Fetch models from LiteLLM"""
    try:
        headers = {
            'Authorization': 'Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb'
        }
        response = requests.get('http://litellm:4000/v1/models', headers=headers, timeout=10)
        if response.status_code == 200:
            data = response.json()
            models = []
            for model in data.get('data', []):
                models.append({
                    'id': model['id'],
                    'name': model['id'],
                    'provider': 'litellm',
                    'base_model_id': model['id'],
                    'size': 0,  # LiteLLM does not provide size
                    'details': {'object': model.get('object', 'model')},
                    'modified_at': datetime.now().isoformat()
                })
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
        cursor.execute('SELECT id, base_model_id FROM model')
        existing_models = {row[1]: row[0] for row in cursor.fetchall()}

        synced_count = 0
        for model in models:
            model_id = model['base_model_id']

            if model_id not in existing_models:
                # Insert new model
                new_uuid = str(uuid.uuid4())
                params = {
                    'provider': model['provider'],
                    'size': model['size'],
                    'details': model['details']
                }

                cursor.execute("""
                    INSERT INTO model (id, user_id, base_model_id, name, params, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (
                    new_uuid,
                    'b7d1b761-a554-4b77-bd90-7b048ce4b177',  # Admin user ID
                    model_id,
                    model['name'],
                    json.dumps(params),
                    datetime.now(),
                    datetime.now()
                ))
                synced_count += 1
                print(f"✅ Added model: {model['name']} ({model['provider']})")
            else:
                # Update existing
                params = {
                    'provider': model['provider'],
                    'size': model['size'],
                    'details': model['details']
                }

                cursor.execute("""
                    UPDATE model
                    SET params = %s, updated_at = %s
                    WHERE base_model_id = %s
                """, (
                    json.dumps(params),
                    datetime.now(),
                    model_id
                ))
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
