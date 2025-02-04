## scraping

This module contains python code for scraping eBay to create a Pokémon card dataset.

## Getting started

1. Create virtual environment and install dependencies:
```
python -m venv venv/
source venv/bin/activate
pip install -r scraping/requirements.txt
```

2. Configure playwright:
```
playwright install
```

3. Run web scraping script:
```
python scraping/scraper.py
```
