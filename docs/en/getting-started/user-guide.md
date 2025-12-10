---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# ERNI-KI User Guide

> **Document Version:**8.0**Updated:**2025-08-29**Target Audience:**End Users
> [TOC]

## Introduction

ERNI-KI is a modern AI platform based on OpenWebUI v0.6.40, providing a
user-friendly web interface for working with language models. The system
supports AI chat, internet search, document processing, and voice interaction
with GPU acceleration and enterprise-grade performance.

### Current System Status (v8.0 - 2025-08-29)

-**Full Functionality**: 33/33 containers Healthy -**External Access**: All 5
domains active (Cloudflare tunnels restored) -**Performance**: System response
time <0.01 seconds -**AI Capabilities**: 9 Ollama models with GPU acceleration
(25% utilization) -**RAG Search**: SearXNG integration with 6+ sources (<2s
response)

## First Steps

### Accessing the System

1. Open your browser and navigate to your ERNI-KI system address
2. Create an administrator account upon first access
3. Log in with your credentials

### System Interface

The main interface consists of:

-**Sidebar**- chat list and settings -**Central Area**- chat window with
AI -**Input Field**- message field and action buttons -**Top Bar**- model
selection and additional settings

## Working with Chats

### Creating a New Chat

1. Click**"+ New Chat"**in the sidebar
2. Select a language model from the dropdown list
3. Enter your first question or prompt
4. Press**Enter**or the send button

### Managing Chats

-**Rename**: Click on chat title → "Rename" -**Delete**: Click the trash icon
next to the chat -**Archive**: Move old chats to archive -**Search**: Use search
to quickly find chats

### Message Types

-**Text Messages**- standard communication with AI -**System Prompts**- special
instructions for AI -**Files and Documents**- upload for analysis (up to
100MB) -**Images**- image analysis and description

## Search and RAG

### Web Search (SearXNG)

1. Enter a query in chat that requires up-to-date information
2. AI will automatically perform an internet search
3. Results will be integrated into the response 4.**Performance**: <2s response
   time, result caching

### Document Search

1. Upload documents via the interface
2. Ask questions about document content
3. AI will find relevant information and provide answers
4. Supported formats: PDF, DOCX, TXT, MD

## Working with Documents

### Uploading Documents

1. Click the paperclip icon in the input field
2. Select files from your computer (up to 100MB)
3. Wait for processing to complete
4. Documents will be available for search and analysis

### Supported Formats

-**Text**: PDF, DOCX, TXT, MD, RTF -**Images**: PNG, JPG, JPEG, GIF (with
OCR) -**Presentations**: PPTX, ODP -**Spreadsheets**: XLSX, CSV, ODS

### OCR and Multilingual Support

-**Supported Languages**: English, German, French, Italian -**Automatic Language
Detection**: Enabled -**High-Quality Recognition**: EasyOCR technology

## Voice Functions

### Voice Input

1. Click the microphone icon in the input field
2. Allow microphone access in browser
3. Speak clearly
4. Click stop to finish recording

### Voice Output (EdgeTTS)

1. Enable voice output in settings
2. Select preferred voice and language
3. AI will vocalize its responses
4. Multiple languages and voices supported

## Settings and Personalization

### Model Settings

-**Temperature**: Controls response creativity (0.1-2.0) -**Max Length**:
Response length limit -**Top-p**: Controls response diversity -**System
Prompt**: Base instructions for AI

### Interface Settings

-**Theme**: Light/Dark interface theme -**Language**: Interface language
selection -**Notifications**: Push notification settings -**Auto-save**:
Automatic chat saving

### Performance Settings

-**Caching**: Enable search query caching -**Preloading**: Model
preloading -**Optimization**: Settings for slow connections

## Monitoring and Statistics

### Personal Statistics

-**Chat Count**: Total number of created chats -**Messages**: Number of sent
messages -**Usage Time**: Total system usage time -**Favorite Models**: Most
used models

### System Information

-**Service Status**: Availability of all system components -**Performance**:
Response time and system load -**Available Models**: List of active language
models -**System Version**: Current ERNI-KI version

### RAG Panels (Grafana)

- OpenWebUI dashboard contains panels:
- RAG p95 Latency (SLA: <2 sec — red threshold at 2s)
- RAG Sources Count (number of sources in response)
- For correct metrics, specify real RAG endpoint in variable `RAG_TEST_URL`
  (service `rag-exporter`).

## Security and Privacy

### Data Protection

-**Local Storage**: All data stored locally -**Encryption**: SSL/TLS encryption
for all traffic -**Backups**: Automatic backups every 24 hours -**Access
Control**: JWT authentication

### Security Recommendations

- Use strong passwords
- Update system regularly
- Do not share confidential information
- Monitor security logs

## Troubleshooting

### Common Issues

**Slow System Performance:**

- Check internet connection
- Clear browser cache
- Refresh page

**File Upload Errors:**

- Check file size (<100MB)
- Ensure supported format
- Try another browser

**File Uploaded but Sources Not Showing:**

- Ensure adaptive RAG threshold is enabled
  (`RAG_ENABLE_RELEVANCE_FALLBACK=true`)
- If necessary, lower `RAG_FALLBACK_RELEVANCE_THRESHOLD` (0 disables result
  filtering)
- Restart OpenWebUI service after changing variables

**Voice Issues:**

- Check microphone permissions
- Ensure internet connection quality
- Try another browser

### Getting Help

-**Documentation**: Full documentation in Help section -**FAQ**: Frequently
Asked Questions -**Technical Support**: Contact system
administrator -**Community**: ERNI-KI user forum

## Tips for Effective Use

### Query Optimization

- Formulate clear and specific questions
- Use context from previous messages
- Experiment with different models
- Use system prompts for specialized tasks

### Working with Large Documents

- Split large documents into parts
- Use specific questions for sections
- Apply keyword search
- Save important results

### Maximum Performance

- Use caching for repetitive queries
- Optimize uploaded file size
- Close unused chats
- Regularly clear history

---

_Document updated for ERNI-KI v8.0 reflecting system restoration, Cloudflare
tunnel fixes, and component updates._
