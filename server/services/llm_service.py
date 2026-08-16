import os
from groq import AsyncGroq
from config import Settings


class LLMService:
    def get_client(self):
        settings = Settings()
        api_key = settings.GROQ_API_KEY.strip(' "\'\n\r\t') or os.getenv("GROQ_API_KEY", "").strip(' "\'\n\r\t')
        
        if not api_key:
            print("[LLMService Warning] GROQ_API_KEY is empty in Settings and os.environ!")
            return AsyncGroq()
        
        return AsyncGroq(api_key=api_key)

    async def generate_response(self, query: str, search_results: list[dict]):
        client = self.get_client()

        if search_results:
            context_text = "\n\n".join(
                [
                    f"Source {i+1} ({result.get('url', '')}):\n{result.get('content', '')}"
                    for i, result in enumerate(search_results)
                    if result.get('content')
                ]
            )
        else:
            context_text = "No external web sources found."

        query_lower = query.lower()
        coding_keywords = [
            "code", "python", "flutter", "dart", "java", "c++", "cpp", "js", "javascript",
            "html", "css", "sql", "algorithm", "program", "function", "script", "class",
            "write a", "implement", "debug", "error", "syntax", "array", "list", "sort", "quicksort"
        ]
        is_coding = any(kw in query_lower for kw in coding_keywords)

        if is_coding:
            full_prompt = f"""
            You are Nova, an expert AI software engineer and computer scientist.

            User Query:
            {query}

            Context from web search (use only as reference if helpful):
            {context_text}

            Instructions:
            - Write complete, fully functional, production-ready code.
            - Always format code inside markdown code blocks specifying the exact language identifier (e.g. ```python, ```dart, ```cpp, ```javascript, ```sql, ```html).
            - Do NOT truncate code or use lazy comments like "# logic goes here". Provide full working solutions.
            - Provide a clear, concise explanation of how the code works after the code block.
            """
        else:
            full_prompt = f"""
            You are Nova, an intelligent AI assistant.

            Context from web search:
            {context_text}

            User Query:
            {query}

            Instructions:
            - Directly and comprehensively answer what the user is asking.
            - If web search context is available and relevant, use it to enrich your answer and cite relevant sources naturally.
            - If math or reasoning query, work through step-by-step logically.
            - Never state that you cannot answer due to lack of search results.
            """

        try:
            response = await client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "You are Nova, an expert AI assistant specializing in software engineering, coding, math reasoning, and general intelligence. Provide direct, complete, fully working code blocks and accurate answers."
                    },
                    {
                        "role": "user",
                        "content": full_prompt
                    }
                ],
                stream=True
            )

            async for chunk in response:
                text = chunk.choices[0].delta.content
                if text:
                    yield text
        except Exception as e:
            print("Groq primary model error, trying fallback model:", e)
            try:
                response = await client.chat.completions.create(
                    model="llama-3.1-8b-instant",
                    messages=[
                        {
                            "role": "system",
                            "content": "You are Nova, an expert AI software engineer and assistant."
                        },
                        {
                            "role": "user",
                            "content": full_prompt
                        }
                    ],
                    stream=True
                )

                async for chunk in response:
                    text = chunk.choices[0].delta.content
                    if text:
                        yield text
            except Exception as err:
                print("Groq fallback error:", err)
                if search_results:
                    yield "Here is the information found for your search query:\n\n"
                    for i, res in enumerate(search_results[:3]):
                        title = res.get('title', 'Source')
                        content = res.get('content', '').strip()
                        if content:
                            yield f"### {i+1}. {title}\n{content[:350]}...\n\n"
                else:
                    yield "Hello! I am ready to answer your questions. Please ask your question again."