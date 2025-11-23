#!/usr/bin/env python3
"""
OpenAI Assistant API Wrapper for ERNI-KI
Provides a simple interface to work with OpenAI Assistant via LiteLLM
"""

import requests
import json
import time
import os
from typing import Dict, List, Optional

class AssistantAPIWrapper:
    def __init__(self,
                 litellm_base_url: str = "http://localhost:4000",
                 api_key: str = "sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb",
                 assistant_id: str = "asst_C8dUl6EKuR41O9sddVVuhTGn"):
        self.base_url = litellm_base_url
        self.api_key = api_key
        self.assistant_id = assistant_id
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

    def create_thread(self) -> Optional[str]:
        """Create a new thread for the Assistant"""
        try:
            response = requests.post(f"{self.base_url}/v1/threads",
                                   headers=self.headers, json={}, timeout=30)

            if response.status_code == 200:
                thread_data = response.json()
                return thread_data['id']
            else:
                print(f"Error creating thread: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            print(f"Exception creating thread: {e}")
            return None

    def add_message(self, thread_id: str, content: str, role: str = "user") -> Optional[str]:
        """Add a message to the thread"""
        try:
            message_data = {
                "role": role,
                "content": content
            }

            response = requests.post(f"{self.base_url}/v1/threads/{thread_id}/messages",
                                   headers=self.headers, json=message_data, timeout=30)

            if response.status_code == 200:
                message = response.json()
                return message['id']
            else:
                print(f"Error adding message: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            print(f"Exception adding message: {e}")
            return None

    def create_run(self, thread_id: str, instructions: str = None) -> Optional[str]:
        """Create a run for the Assistant"""
        try:
            run_data = {
                "assistant_id": self.assistant_id
            }

            if instructions:
                run_data["instructions"] = instructions

            response = requests.post(f"{self.base_url}/v1/threads/{thread_id}/runs",
                                   headers=self.headers, json=run_data, timeout=30)

            if response.status_code == 200:
                run = response.json()
                return run['id']
            else:
                print(f"Error creating run: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            print(f"Exception creating run: {e}")
            return None

    def wait_for_run_completion(self, thread_id: str, run_id: str, max_wait: int = 60) -> Optional[str]:
        """Wait for run completion and return status"""
        try:
            for attempt in range(max_wait):
                # Direct call to OpenAI API via requests
                openai_headers = {
                    "Authorization": f"Bearer {os.environ.get('OPENAI_API_KEY')}",
                    "Content-Type": "application/json",
                    "OpenAI-Beta": "assistants=v2"
                }

                response = requests.get(f"https://api.openai.com/v1/threads/{thread_id}/runs/{run_id}",
                                      headers=openai_headers, timeout=30)

                if response.status_code == 200:
                    run_status = response.json()
                    status = run_status.get('status')

                    if status == 'completed':
                        return 'completed'
                    elif status in ['failed', 'cancelled', 'expired']:
                        print(f"Run failed with status: {status}")
                        return status
                    else:
                        time.sleep(1)
                else:
                    print(f"Error getting run status: {response.status_code} - {response.text}")
                    time.sleep(1)

            return 'timeout'

        except Exception as e:
            print(f"Exception waiting for run: {e}")
            return None

    def get_messages(self, thread_id: str) -> List[Dict]:
        """Get all messages from the thread"""
        try:
            # Direct call to OpenAI API
            openai_headers = {
                "Authorization": f"Bearer {os.environ.get('OPENAI_API_KEY')}",
                "Content-Type": "application/json",
                "OpenAI-Beta": "assistants=v2"
            }

            response = requests.get(f"https://api.openai.com/v1/threads/{thread_id}/messages",
                                  headers=openai_headers, timeout=30)

            if response.status_code == 200:
                messages = response.json()
                return messages.get('data', [])
            else:
                print(f"Error getting messages: {response.status_code} - {response.text}")
                return []

        except Exception as e:
            print(f"Exception getting messages: {e}")
            return []

    def chat_with_assistant(self, message: str, instructions: str = None) -> Optional[str]:
        """Full chat cycle with the Assistant"""
        print(f"💬 Sending message to Assistant: {message[:50]}...")

        # 1. Create thread
        thread_id = self.create_thread()
        if not thread_id:
            return None
        print(f"✅ Thread created: {thread_id}")

        # 2. Add user message
        message_id = self.add_message(thread_id, message)
        if not message_id:
            return None
        print(f"✅ Message added: {message_id}")

        # 3. Create run
        run_id = self.create_run(thread_id, instructions)
        if not run_id:
            return None
        print(f"✅ Run created: {run_id}")

        # 4. Wait for completion
        status = self.wait_for_run_completion(thread_id, run_id)
        if status != 'completed':
            print(f"❌ Run did not complete successfully: {status}")
            return None
        print(f"✅ Run completed: {status}")

        # 5. Get answer
        messages = self.get_messages(thread_id)
        for msg in messages:
            if msg.get('role') == 'assistant':
                content = msg.get('content', [])
                if content and len(content) > 0:
                    text = content[0].get('text', {}).get('value', '')
                    print(f"✅ Answer received: {len(text)} chars")
                    return text

        print("❌ Assistant answer not found")
        return None

def main():
    """Demonstration of Assistant API Wrapper"""
    print("🚀 Testing OpenAI Assistant API Wrapper")
    print("=" * 60)

    # Check OpenAI API key
    if not os.environ.get('OPENAI_API_KEY'):
        print("❌ OPENAI_API_KEY is not set in environment")
        return 1

    # Create wrapper
    assistant = AssistantAPIWrapper()

    # Тестовое сообщение
    test_message = "Hello! This is a test of the OpenAI Assistant integration through ERNI-KI system. Please confirm that you can receive and respond to this message."

    # Отправляем сообщение
    response = assistant.chat_with_assistant(
        message=test_message,
        instructions="Please respond briefly to confirm the integration is working."
    )

    if response:
        print("\n" + "=" * 60)
        print("✅ УСПЕХ! OpenAI Assistant API интеграция работает!")
        print(f"📝 Ответ Assistant:\n{response}")
        print("\n📋 Статус интеграции:")
        print("   • LiteLLM может создавать threads и messages")
        print("   • OpenAI Assistant API доступен напрямую")
        print("   • Полный цикл общения функционирует")
        print("   • Система готова к использованию")
        return 0
    else:
        print("\n" + "=" * 60)
        print("❌ ОШИБКА! Интеграция требует доработки")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
