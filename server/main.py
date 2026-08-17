import asyncio
import traceback
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from models.chat_body import ChatBody
from services.llm_service import LLMService
from services.search_service import SearchService

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

search_service = SearchService()
llm_service = LLMService()


@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": "Nova AI Backend Server",
        "websocket_endpoint": "/ws/chat",
        "docs": "/docs"
    }


@app.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("[WS] Client connected to /ws/chat")

    try:
        while True:
            data = await websocket.receive_json()
            query = data.get("query")

            if query:
                print(f"[WS] Received query: {query}")
                search_results = await asyncio.to_thread(search_service.web_search, query)

                print(f"[WS] Search completed for query: {query}, results count: {len(search_results)}")
                await websocket.send_json({
                    "type": "search_result",
                    "data": search_results
                })

                async for chunk in llm_service.generate_response(
                    query,
                    search_results
                ):
                    await websocket.send_json({
                        "type": "content",
                        "data": chunk
                    })

    except WebSocketDisconnect:
        print("[WS] Client disconnected normally")
    except Exception as e:
        print(f"[WS] Exception in endpoint: {e}")
        traceback.print_exc()

    finally:
        try:
            await websocket.close()
        except Exception:
            pass


@app.post("/chat")
async def chat_endpoint(body: ChatBody):
    search_results = await asyncio.to_thread(search_service.web_search, body.query)

    response_chunks = []
    async for chunk in llm_service.generate_response(
        body.query,
        search_results
    ):
     response_chunks.append(chunk)

    return {"response": "".join(response_chunks), "sources": search_results}