def extract_image_url(img_tag):
    """Extracts the best image URL from an <img> tag inside the gallery."""
    if "data-zoom-src" in img_tag.attrs:
        return img_tag["data-zoom-src"]
    elif "data-originalsrc" in img_tag.attrs:  # extracting images from category page
        return img_tag["data-originalsrc"]
    elif "srcset" in img_tag.attrs:
        return img_tag["srcset"].split(",")[-1].split(" ")[0]
    elif "src" in img_tag.attrs:
        return img_tag["src"]
    return None


def sanitize_filename(filename):
    """Removes invalid characters from filenames."""
    return "".join(c for c in filename if c.isalnum() or c in " -_").strip()
