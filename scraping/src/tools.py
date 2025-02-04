import os
import time
from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import requests

from .parse import extract_image_url, sanitize_filename
from .io import download_image


def get_product_urls_with_playwright(max_pages:int, category_url: str):
    """
    Uses Playwright to scrape product URLs from dynamically loaded eBay category pages.
    """
    product_urls = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        for page_num in range(1, max_pages + 1):
            url = category_url.format(page_num)
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


def scrape_ebay_product(url, headers, base_image_folder):
    """Scrapes an eBay product page for its name, condition, price, and all images."""
    print(f"Scraping product: {url}")
    
    response = requests.get(url)
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
    product_folder = os.path.join(base_image_folder, sanitize_filename(title))
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
        filename = download_image(image_url, product_folder, index, headers)
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
