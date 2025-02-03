import os
import time
import random
import pandas as pd
from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import requests

# Headers to mimic a real browser (used in requests for product pages)
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
}

# Folder to store all product images
BASE_IMAGE_FOLDER = "ebay_pokemon_psa"
os.makedirs(BASE_IMAGE_FOLDER, exist_ok=True)

# eBay Category URL for Pokémon PSA Individual Cards
CATEGORY_URL = "https://www.ebay.com/b/Pokemon-TCG-Professional-Sports-Authenticator-PSA-Individual-Trading-Card-Games/183454/bn_55173600?_pgn={}"

def get_product_urls_with_playwright(max_pages=2):
    """
    Uses Playwright to scrape product URLs from dynamically loaded eBay category pages.
    """
    product_urls = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        for page_num in range(1, max_pages + 1):
            url = CATEGORY_URL.format(page_num)
            print(f"Scraping category page {page_num}: {url}")
            page.goto(url)
            time.sleep(5)  # Wait for JavaScript to load

            # Extract page content after JS rendering
            soup = BeautifulSoup(page.content(), "html.parser")
            items = soup.find_all("a", class_="brwrvr__item-card__image-link")

            for item in items:
                product_url = item["href"]
                if product_url.startswith("/itm/"):
                    product_url = "https://www.ebay.com" + product_url
                product_urls.append(product_url)

            print(f"Extracted {len(product_urls)} product URLs from page {page_num}")

        browser.close()

    print(f"Total URLs extracted: {len(product_urls)}")
    return product_urls

def sanitize_filename(filename):
    """Removes invalid characters from filenames."""
    return "".join(c for c in filename if c.isalnum() or c in " -_").strip()

def download_image(image_url, folder, index):
    """Downloads an image and saves it in the specified folder."""
    if not image_url:
        return None

    try:
        response = requests.get(image_url, headers=HEADERS, stream=True)
        if response.status_code == 200:
            filename = f"{index}.jpg"
            filepath = os.path.join(folder, filename)
            with open(filepath, "wb") as file:
                for chunk in response.iter_content(1024):
                    file.write(chunk)
            return filename
        else:
            print(f"Failed to download image: {image_url} (Status: {response.status_code})")
    except Exception as e:
        print(f"Error downloading {image_url}: {e}")
    
    return None

def extract_image_url(img_tag):
    """Extracts the best image URL from an <img> tag inside the gallery."""
    if "data-zoom-src" in img_tag.attrs:
        return img_tag["data-zoom-src"]
    elif "data-originalsrc" in img_tag.attrs:  # Extracting images from category page
        return img_tag["data-originalsrc"]
    elif "srcset" in img_tag.attrs:
        return img_tag["srcset"].split(",")[-1].split(" ")[0]
    elif "src" in img_tag.attrs:
        return img_tag["src"]
    return None

def scrape_ebay_product(url):
    """Scrapes an eBay product page for its name, condition, price, and all images."""
    print(f"Scraping product: {url}")
    
    response = requests.get(url, headers=HEADERS)
    if response.status_code != 200:
        print(f"Failed to fetch page (Status: {response.status_code})")
        return None

    soup = BeautifulSoup(response.text, "html.parser")

    # Extract product name
    title_element = soup.find("h1", class_="x-item-title__mainTitle")
    title = title_element.text.strip() if title_element else "Unknown Product"

    # Extract price
    price_element = soup.find("span", class_="x-price-primary")
    price = price_element.text.strip() if price_element else "N/A"

    # Extract condition (New, Used, PSA Graded, etc.)
    condition_element = soup.find("div", class_="x-item-condition-text")
    condition = condition_element.text.strip() if condition_element else "N/A"

    # Create a dedicated folder for the product
    product_folder = os.path.join(BASE_IMAGE_FOLDER, sanitize_filename(title))
    os.makedirs(product_folder, exist_ok=True)

    # Restrict image scraping to the main image carousel
    image_gallery = soup.find("div", class_="ux-image-carousel")
    if not image_gallery:
        print("No image gallery found!")
        return {"Title": title, "Condition": condition, "Price": price, "URL": url, "Image Count": 0, "Image Folder": product_folder}

    # Extract images only from the image gallery
    image_elements = image_gallery.find_all("img")
    image_urls = [extract_image_url(img) for img in image_elements if extract_image_url(img)]

    # Remove duplicates
    image_urls = list(set(image_urls))

    # Download images
    downloaded_images = []
    for index, image_url in enumerate(image_urls):
        filename = download_image(image_url, product_folder, index)
        if filename:
            downloaded_images.append(filename)

    return {
        "Title": title,
        "Condition": condition,
        "Price": price,
        "URL": url,
        "Image Count": len(downloaded_images),
        "Image Folder": product_folder,
    }

# Step 1: Get product URLs from category page using Playwright
product_urls = get_product_urls_with_playwright(max_pages=2)

# Step 2: Scrape each product page
results = []
for product_url in product_urls:
    product_data = scrape_ebay_product(product_url)
    if product_data:
        results.append(product_data)

# Save results to CSV
df = pd.DataFrame(results)
df.to_csv("ebay_pokemon_psa_data.csv", index=False)

print("\nScraping completed! Data saved to 'ebay_pokemon_psa_data.csv'.")
print(df.head())
