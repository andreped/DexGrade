import os
import random
import requests
import time
from bs4 import BeautifulSoup
from tqdm import tqdm
from PIL import Image
from io import BytesIO


def get_search_results(search_query: str, max_results: int=10, grade:int|None=None):
    base_url = "https://www.ebay.com/sch/i.html"
    params = {"_nkw": search_query, "_sop": 12}  # Sort by newly listed

    if grade is not None:
        params["Grade"] = grade
    
    response = requests.get(base_url, params=params)
    if response.status_code != 200:
        print("Failed to retrieve search results.")
        return []
    
    soup = BeautifulSoup(response.text, "html.parser")
    for item in soup.select(".s-item")[:max_results]:
        link_tag = item.select_one(".s-item__link")
        if link_tag and link_tag['href'].startswith("https://www.ebay.com/itm/"):
            yield link_tag['href']


def get_ebay_listings(search_url: str):
    response = requests.get(search_url)
    if response.status_code != 200:
        print("Failed to retrieve search results.")
        return []
    
    soup = BeautifulSoup(response.text, 'html.parser')
    listings = []
    for item in soup.select(".s-item"):
        link_tag = item.select_one(".s-item__link")
        if link_tag and link_tag['href'].startswith("https://www.ebay.com/itm/"):
            listings.append(link_tag['href'])
    return listings


def get_psa_grade(listing_url: str) -> int | None:
    response = requests.get(listing_url)
    if response.status_code != 200:
        print(f"Failed to retrieve listing: {listing_url}")
        return None
    
    soup = BeautifulSoup(response.text, "html.parser")
    grade_text = None
    
    for span in soup.find_all("span", class_="ux-textspans"):
        if "Graded - PSA" in span.text:
            grade_text = span.text.strip()
            break
    
    if not grade_text:
        return None
    
    try:
        grade = int(grade_text.split("PSA ")[-1])
        return grade
    except ValueError:
        return None


def download_images(listing_url: str, grade: int, listing_id: int, nb_images: int = 5) -> None:
    response = requests.get(listing_url)
    if response.status_code != 200:
        print(f"Failed to retrieve listing: {listing_url}")
        return
    
    soup = BeautifulSoup(response.text, "html.parser")
    image_tags = soup.select("img")
    image_urls = []
    
    for img in image_tags:
        if "src" in img.attrs:
            img_url = img["src"]
            image_urls.append(img_url)
    
    image_urls = image_urls[:nb_images]  # Get first K images
    
    save_path = f"./psa_dataset/{grade}/{listing_id}/"
    os.makedirs(save_path, exist_ok=True)
    
    for i, img_url in enumerate(image_urls):
        if img_url == "":
            print("Post had no images. Skipping...")
            break
        
        img_response = requests.get(img_url)
        if img_response.status_code != 200:
            print(f"Failed to retrieve image: {img_url}")
            continue
        
        # Use Pillow to get the image size
        image = Image.open(BytesIO(img_response.content))
        width, height = image.size

        # ignore if image is too small
        if width < 300 or height < 300:
            continue
        
        img_data = img_response.content
        with open(os.path.join(save_path, f"image_{i+1}.png"), "wb") as img_file:
            img_file.write(img_data)

        # Only download the first valid image -> skip remaining images
        break


def main(search_query: str, max_results: int, nb_images):
    # Iterate over all 1-10 PSA categories
    for grade_gt in tqdm(range(1, 11), "Grade"):
        listing_generator = get_search_results(search_query, max_results=max_results, grade=grade_gt)

        for count, listing_url in tqdm(enumerate(listing_generator), "Listing", total=max_results):
            grade = get_psa_grade(listing_url)
            if grade is not None:
                download_images(listing_url, grade, count, nb_images)
            
            time.sleep(random.uniform(2, 5))  # Avoid rate-limiting


if __name__ == "__main__":
    main(search_query="pokemon psa", max_results=20)
