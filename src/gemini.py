# ============================================
# GEMINI CLIENT WITH ERROR HANDLING
# ============================================

import os
import time
from dotenv import load_dotenv
from google import genai

# Load .env values
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Create Gemini client
client = genai.Client(api_key=GEMINI_API_KEY)


def ask_gemini(prompt):
    """
    Send prompt to Gemini.
    Handles temporary overload and quota errors.
    """

    max_attempts = 3

    for attempt in range(1, max_attempts + 1):

        try:
            response = client.models.generate_content(
                model="gemini-3.8-flash",
                contents=prompt
            )

            return response.text

        except Exception as error:

            error_text = str(error)

            # --------------------------------
            # Daily/free-tier quota exhausted
            # --------------------------------
            if "429" in error_text or "RESOURCE_EXHAUSTED" in error_text:

                print("\nGemini quota exhausted.")
                print("Please try again after the free-tier quota resets.")

                return None

            # --------------------------------
            # Temporary Gemini server overload
            # --------------------------------
            if "503" in error_text or "UNAVAILABLE" in error_text:

                print(f"\nGemini attempt {attempt} failed.")

                if attempt < max_attempts:
                    print("Gemini is busy. Retrying in 5 seconds...")
                    time.sleep(5)
                    continue

                print("Gemini is currently unavailable.")
                return None

            # Other unexpected errors
            print("\nGemini error:")
            print(error)

            return None


# Test Gemini connection
if __name__ == "__main__":

    result = ask_gemini(
        "Reply only with: Gemini connection successful."
    )

    if result:
        print(result)