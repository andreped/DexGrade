import os
import requests


def download_image(image_url, folder, index, headers):
    """Downloads an image and saves it in the specified folder."""
    if not image_url:
        return None

    try:
        response = requests.get(image_url, headers=headers, stream=True)
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
