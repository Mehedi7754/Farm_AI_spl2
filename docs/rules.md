# FarmAI Development and Deployment Rules

This document outlines critical codebase, architecture, and deployment rules for the FarmAI project. All future AI agents and developers must strictly adhere to these rules.

---

## 1. Backend & AI Model Rules

### 1.1 AI Model Selection
* **Primary LLM Model**: The Groq model for the AI Voice Assistant and Symptom Checker must always be `qwen/qwen3.6-27b`.
* **Reasoning / Think Blocks**: The Qwen model outputs thinking paths inside `<think>...</think>` tags. The backend code must always parse and strip these blocks before returning the clean Bengali response to the client.
* **Token Limits**: Always set `max_completion_tokens: 4000` (or higher) for the Qwen model. If set too low (e.g., 1000), the model will consume all tokens in the thinking block and fail to return any actual response content.
* **Invalid API Parameters**: Do **NOT** pass the `reasoning_effort` parameter to Groq's Chat Completions endpoint for Qwen or Llama models unless they explicitly support it. Doing so throws a **400 Bad Request** validation error, breaking the API.

---

## 2. Server & Deployment Rules

### 2.1 Compiling on EC2 (CRITICAL)
* **Never Compile Locally on EC2**: The AWS EC2 micro-instance has only 1GB of RAM and no swap space. Running `npm run build` on the server will cause the CPU to lock up, run out of memory, and completely freeze the server (causing SSH and API connection timeouts).
* **Safe Build Process**:
  1. Build the project locally on the developer machine (`npm run build` in the `apis/` folder).
  2. Compress the output folder: `tar -czf dist.tar.gz dist`.
  3. Upload the archive to the server: `scp -i ~/Downloads/mail2.pem dist.tar.gz ubuntu@3.106.54.54:/home/ubuntu/apis/`.
  4. Extract and restart PM2 on the server: `ssh -i ~/Downloads/mail2.pem ubuntu@3.106.54.54 "cd /home/ubuntu/apis && tar -xzf dist.tar.gz && pm2 restart farmai-api"`.

### 2.2 Database Containers
* The PostgreSQL database runs inside a Docker container mapped to host port `5433`.
* If the server reboots, ensure the conflicting container named `farm-ai-postgres` is removed (`docker rm -f farm-ai-postgres`) and restarted correctly using docker-compose: `docker compose up -d postgres` inside the `/home/ubuntu/apis` directory.

---

## 3. Flutter Client Rules

### 3.1 Voice Assistant Screen (`VoiceChatScreen`)
* **Prevent Duplicate Submissions**: Always use a synchronous boolean flag (like `_isQueryProcessing`) to guard the Groq query helper `_sendQueryToGroq`. Microphone libraries trigger `onResult(finalResult: true)` and `onStatus(done)` concurrently, causing duplicate API requests if not properly locked.
* **Microphone Timing**: Set the silent listening timeout `pauseFor` to exactly `3 seconds`. Less than 3 seconds cuts off farmers speaking slowly; more than 3 seconds causes excessive lag.
* **Memory Safety**: Always call `_speech.cancel()` during the widget's `dispose()` lifecycle instead of `stop()`, and verify all async callbacks check `if (mounted)` before calling `setState`.
* **Animation Recycling Keys**: Use a unique `ValueKey` (incorporating message index and text hash) for ListView items. This prevents list scroll recycling from triggering duplicate fade-in animations.
