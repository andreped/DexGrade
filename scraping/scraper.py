import os
import platform
import pandas as pd

from src.tools import scrape_ebay_product, get_product_urls_with_playwright


def get_user_agent():
    """Returns an appropriate User-Agent based on the operating system."""
    system = platform.system()
    if system == "Windows":
        return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    elif system == "Darwin":  # macOS
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    else:  # Assume Linux/Ubuntu
        return "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"


def main():
    # Create a base folder for storing images (cross-platform)
    base_image_folder = os.path.join(os.getcwd(), "ebay_pokemon_psa")
    os.makedirs(base_image_folder, exist_ok=True)

    # eBay Category URL for Pokémon PSA Individual Cards
    category_url = "https://www.ebay.com/b/Pokemon-TCG-Professional-Sports-Authenticator-PSA-Individual-Trading-Card-Games/183454/bn_55173600?_pgn={}"

    # Set headers dynamically
    headers = {
        "User-Agent": get_user_agent(),
        "Accept-Language": "en-US,en;q=0.9",
    }

    # Step 1: Get product URLs using Playwright
    product_urls = get_product_urls_with_playwright(max_pages=2, category_url=category_url)

    # Step 2: Scrape each product page
    results = []
    for product_url in product_urls:
        product_data = scrape_ebay_product(url=product_url, headers=headers, base_image_folder=base_image_folder)
        if product_data:
            results.append(product_data)

    # Save results to CSV
    df = pd.DataFrame(results)
    df.to_csv(os.path.join(os.getcwd(), "ebay_pokemon_psa_data.csv"), index=False)

    print("\nScraping completed! Data saved to 'ebay_pokemon_psa_data.csv'.")
    print(df.head())


if __name__ == "__main__":
    main()
