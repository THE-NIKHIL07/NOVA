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

        full_prompt = f"""
        You are Nova, an elite, highly intelligent AI assistant specializing in coding, mathematics, logical reasoning, and general knowledge.

        Context from web search:
        {context_text}

        User Query:
        {query}

        Instructions:
        - For CODING queries (Python, Flutter, C++, Java, JavaScript, HTML/CSS, SQL, algorithms, etc.):
          Provide complete, production-ready, fully functional code inside markdown code blocks with language identifiers (e.g. ```python ... ``` or ```dart ... ```). Explain how the code works clearly. Do NOT truncate code or rely solely on web search snippets.
        - For MATH / REASONING queries:
          Work through the problem step-by-step with clear logical explanation and clear final answers.
        - For GENERAL / SEARCH queries:
          Use web search context when relevant to enrich your answer and cite sources naturally.
        - NEVER refuse to answer or state that you lack web search context. Use your own internal AI intelligence to provide an accurate, high-quality solution.
        """

        try:
            response = await client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "You are Nova, an elite AI assistant skilled in coding, math reasoning, algorithms, and general intelligence. Provide direct, complete, and perfectly formatted answers."
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
                            "content": "You are Nova, an intelligent AI assistant."
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