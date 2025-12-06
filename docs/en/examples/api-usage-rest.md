---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-30'
---

# REST API Usage Examples

Complete examples for common OpenWebUI REST API operations using curl, Python,
and JavaScript.

## Table of Contents

1. [Authentication](#authentication)
2. [Chat Operations](#chat-operations)
3. [Message Management](#message-management)
4. [Model Management](#model-management)
5. [Document Upload](#document-upload)
6. [User Management](#user-management)

---

## Authentication

### Sign In (Get Token)

**cURL:**

```bash
# Sign in and get JWT token
curl -X POST http://localhost:8080/api/v1/auths/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@localhost",
    "password": "EXAMPLE_PASSWORD" # pragma: allowlist secret
  }' | jq '.token'

# Store token in variable for subsequent requests
TOKEN=$(curl -X POST http://localhost:8080/api/v1/auths/signin \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@localhost","password":"EXAMPLE_PASSWORD"}' \ # pragma: allowlist secret
  | jq -r '.token') # pragma: allowlist secret
```

**Python:**

```python
import requests
import json

API_URL = "http://localhost:8080/api/v1"

def sign_in(email: str, password: str) -> str:
    """Sign in and return JWT token."""
    response = requests.post(
        f"{API_URL}/auths/signin",
        json={"email": email, "password": password}
    )
    response.raise_for_status()
    return response.json()["token"]

# Usage
token = sign_in("admin@localhost", "your-password")
print(f"Token: {token}")
```

**JavaScript:**

```javascript
const API_URL = 'http://localhost:8080/api/v1';

async function signIn(email, password) {
  const response = await fetch(`${API_URL}/auths/signin`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) throw new Error('Sign in failed');
  return (await response.json()).token;
}

// Usage
const token = await signIn('admin@localhost', 'your-password');
console.log(`Token: ${token}`);
```

### Verify Token

**cURL:**

```bash
curl -X GET http://localhost:8080/api/v1/auths/verify \
  -H "Authorization: Bearer $TOKEN"
```

---

## Chat Operations

### List Chats

**cURL:**

```bash
# Get all chats for current user
curl -X GET "http://localhost:8080/api/v1/chats" \
  -H "Authorization: Bearer $TOKEN" | jq .

# List with pagination
curl -X GET "http://localhost:8080/api/v1/chats?skip=0&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

**Python:**

```python
def list_chats(token: str, skip: int = 0, limit: int = 10) -> list:
    """List user's chats."""
    response = requests.get(
        f"{API_URL}/chats",
        params={"skip": skip, "limit": limit},
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()

# Usage
chats = list_chats(token)
for chat in chats:
    print(f"ID: {chat['id']}, Title: {chat['title']}")
```

**JavaScript:**

```javascript
async function listChats(token, skip = 0, limit = 10) {
  const params = new URLSearchParams({ skip, limit });
  const response = await fetch(`${API_URL}/chats?${params}`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!response.ok) throw new Error('Failed to list chats');
  return await response.json();
}

// Usage
const chats = await listChats(token);
chats.forEach(chat => console.log(`${chat.title} (${chat.id})`));
```

### Create Chat

**cURL:**

```bash
curl -X POST http://localhost:8080/api/v1/chats \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Chat",
    "model": "llama2:latest"
  }' | jq .
```

**Python:**

```python
def create_chat(token: str, title: str, model: str) -> dict:
    """Create a new chat."""
    response = requests.post(
        f"{API_URL}/chats",
        json={"title": title, "model": model},
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()

# Usage
chat = create_chat(token, "My Chat", "llama2:latest")
print(f"Created chat: {chat['id']}")
```

**JavaScript:**

```javascript
async function createChat(token, title, model) {
  const response = await fetch(`${API_URL}/chats`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ title, model }),
  });

  if (!response.ok) throw new Error('Failed to create chat');
  return await response.json();
}

// Usage
const chat = await createChat(token, 'My Chat', 'llama2:latest');
console.log(`Created chat: ${chat.id}`);
```

---

## Message Management

### Send Message

**cURL:**

```bash
CHAT_ID="your-chat-id"

curl -X POST http://localhost:8080/api/v1/chats/$CHAT_ID/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, what is 2+2?",
    "model": "llama2:latest"
  }' | jq .
```

**Python:**

```python
def send_message(token: str, chat_id: str, content: str, model: str) -> dict:
    """Send a message to a chat."""
    response = requests.post(
        f"{API_URL}/chats/{chat_id}/messages",
        json={"content": content, "model": model},
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()

# Usage
response = send_message(token, chat_id, "Hello, what is 2+2?", "llama2:latest")
print(f"Assistant: {response['message']['content']}")
```

**JavaScript:**

```javascript
async function sendMessage(token, chatId, content, model) {
  const response = await fetch(`${API_URL}/chats/${chatId}/messages`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ content, model }),
  });

  if (!response.ok) throw new Error('Failed to send message');
  return await response.json();
}

// Usage
const response = await sendMessage(token, chatId, 'Hello, what is 2+2?', 'llama2:latest');
console.log(`Assistant: ${response.message.content}`);
```

### Stream Message (SSE)

**Python:**

```python
def stream_message(token: str, chat_id: str, content: str, model: str):
    """Stream a message response using Server-Sent Events."""
    response = requests.post(
        f"{API_URL}/chats/{chat_id}/messages/stream",
        json={"content": content, "model": model},
        headers={"Authorization": f"Bearer {token}"},
        stream=True
    )
    response.raise_for_status()

    for line in response.iter_lines():
        if line:
            print(line.decode("utf-8"))

# Usage
stream_message(token, chat_id, "Tell me a story", "llama2:latest")
```

**JavaScript:**

```javascript
async function streamMessage(token, chatId, content, model) {
  const response = await fetch(`${API_URL}/chats/${chatId}/messages/stream`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ content, model }),
  });

  if (!response.ok) throw new Error('Failed to stream message');

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    process.stdout.write(chunk);
  }
}

// Usage
await streamMessage(token, chatId, 'Tell me a story', 'llama2:latest');
```

### Get Chat History

**cURL:**

```bash
curl -X GET http://localhost:8080/api/v1/chats/$CHAT_ID/messages \
  -H "Authorization: Bearer $TOKEN" | jq .
```

**Python:**

```python
def get_chat_history(token: str, chat_id: str) -> list:
    """Get all messages in a chat."""
    response = requests.get(
        f"{API_URL}/chats/{chat_id}/messages",
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()

# Usage
messages = get_chat_history(token, chat_id)
for msg in messages:
    role = "You" if msg["role"] == "user" else "Assistant"
    print(f"{role}: {msg['content']}")
```

---

## Model Management

### List Available Models

**cURL:**

```bash
curl -X GET http://localhost:8080/api/v1/models \
  -H "Authorization: Bearer $TOKEN" | jq '.models[] | .id'
```

**Python:**

```python
def list_models(token: str) -> list:
    """List available models."""
    response = requests.get(
        f"{API_URL}/models",
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()["models"]

# Usage
models = list_models(token)
for model in models:
    print(f"- {model['id']} (size: {model.get('size', 'unknown')})")
```

### Pull Model (via Ollama)

**cURL:**

```bash
# Trigger model pull (requires Ollama backend)
curl -X POST http://localhost:8080/api/v1/models/pull \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral:latest"
  }'
```

---

## Document Upload

### Upload Document for RAG

**cURL:**

```bash
# Upload a PDF or document
curl -X POST http://localhost:8080/api/v1/documents \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/document.pdf" \
  -F "collection=my-collection" | jq .
```

**Python:**

```python
def upload_document(token: str, file_path: str, collection: str) -> dict:
    """Upload a document for RAG."""
    with open(file_path, "rb") as f:
        files = {"file": f}
        data = {"collection": collection}
        response = requests.post(
            f"{API_URL}/documents",
            files=files,
            data=data,
            headers={"Authorization": f"Bearer {token}"}
        )

    response.raise_for_status()
    return response.json()

# Usage
result = upload_document(token, "./document.pdf", "my-collection")
print(f"Document ID: {result['id']}")
```

---

## User Management

### Get User Info

**cURL:**

```bash
curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" | jq .
```

**Python:**

```python
def get_user_info(token: str) -> dict:
    """Get current user information."""
    response = requests.get(
        f"{API_URL}/users/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()

# Usage
user = get_user_info(token)
print(f"Name: {user['name']}, Email: {user['email']}")
```

---

## Error Handling

### Common Errors and Solutions

**Authentication Error (401):**

```python
try:
    response = requests.get(
        f"{API_URL}/chats",
        headers={"Authorization": f"Bearer {token}"}
    )
except requests.exceptions.HTTPError as e:
    if e.response.status_code == 401:
        print("Token expired, re-authenticate")
        token = sign_in(email, password)
    else:
        raise
```

**Rate Limiting (429):**

```python
import time

def request_with_retry(url, **kwargs):
    """Make request with exponential backoff retry."""
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = requests.get(url, **kwargs)
            response.raise_for_status()
            return response
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                wait_time = 2** attempt  # Exponential backoff
                print(f"Rate limited, waiting {wait_time}s...")
                time.sleep(wait_time)
            else:
                raise
    raise Exception("Max retries exceeded")
```

---

## Complete Example: Chat with RAG

**Python:**

```python
import requests
import time

class OpenWebUIClient:
    def __init__(self, base_url: str, email: str, password: str):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.token = self._sign_in(email, password)

    def _sign_in(self, email: str, password: str) -> str:
        response = requests.post(
            f"{self.api_url}/auths/signin",
            json={"email": email, "password": password}
        )
        response.raise_for_status()
        return response.json()["token"]

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"}

    def create_chat(self, title: str, model: str) -> str:
        response = requests.post(
            f"{self.api_url}/chats",
            json={"title": title, "model": model},
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()["id"]

    def upload_document(self, file_path: str, collection: str) -> str:
        with open(file_path, "rb") as f:
            response = requests.post(
                f"{self.api_url}/documents",
                files={"file": f},
                data={"collection": collection},
                headers={"Authorization": f"Bearer {self.token}"}
            )
        response.raise_for_status()
        return response.json()["id"]

    def send_message(self, chat_id: str, content: str, model: str) -> str:
        response = requests.post(
            f"{self.api_url}/chats/{chat_id}/messages",
            json={"content": content, "model": model},
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()["message"]["content"]

# Usage
client = OpenWebUIClient(
    "http://localhost:8080",
    "admin@localhost",
    "your-password"
)

# Create chat
chat_id = client.create_chat("RAG Chat", "llama2:latest")
print(f"Created chat: {chat_id}")

# Upload document
doc_id = client.upload_document("./knowledge.pdf", "rag-collection")
print(f"Uploaded document: {doc_id}")

# Chat with RAG context
response = client.send_message(
    chat_id,
    "Based on the uploaded document, what are the key points?",
    "llama2:latest"
)
print(f"Assistant: {response}")
```

---

## Related Documentation

- [API Reference](../reference/api-reference.md)
- [Webhook Examples](../../examples/webhook-client-python.py)
- [OpenWebUI Documentation](https://docs.openwebui.com)
