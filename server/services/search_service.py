from config import Settings
from tavily import TavilyClient
import trafilatura

settings = Settings()

client = TavilyClient(
    api_key=settings.TAVILY_API_KEY
)


class SearchService:
    def web_search(self, query: str):
        try:
            response = client.search(
                query,
                max_results=4
            )

            search_results = response.get("results", [])
            results = []

            for res in search_results:
                url = res.get("url", "")
                raw_content = res.get("content", "")
                final_text = raw_content

                try:
                    downloaded = trafilatura.fetch_url(url)
                    if downloaded:
                        extracted = trafilatura.extract(
                            downloaded,
                            include_comments=False
                        )
                        if extracted:
                            final_text = extracted
                except Exception:
                    pass

                # Truncate content to max 1000 chars per source to fit Groq token limits
                truncated_text = (final_text or "").strip()[:1000]

                results.append({
                    "title": res.get("title", ""),
                    "url": url,
                    "content": truncated_text,
                })

            return results
        except Exception as e:
            print("Search service error:", e)
            return []