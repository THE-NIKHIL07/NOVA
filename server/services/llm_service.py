from groq import AsyncGroq
from config import Settings


class LLMService:
    def get_client(self):
        settings = Settings()
        api_key = settings.GROQ_API_KEY.strip(' "\'\n\r\t')
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
        You are Nova, an intelligent and highly knowledgeable AI assistant.

        Context from web search:
        {context_text}

        User Query:
        {query}

        Instructions:
        - Directly and comprehensively answer what the user is asking.
        - If web search context is available and relevant, use it to enrich your answer and cite relevant sources naturally.
        - If web search context is empty, sparse, or missing relevant details, answer fully and accurately using your own internal AI knowledge.
        - For conversational questions (like "hi", "hello", "how are you"), keep answers natural and friendly.
        - Always provide a helpful, high-quality answer. Never state that you cannot answer due to lack of web search results.
        """

        try:
            response = await client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "You are Nova, an intelligent AI assistant. Provide helpful, direct, and accurate answers."
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
                yield f"\n\n*Error generating response: {str(err)}*"