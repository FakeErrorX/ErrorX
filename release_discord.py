import os
import json
import requests
from pathlib import Path
from datetime import datetime

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
TAG = os.getenv("TAG")
release_file = Path(os.getcwd()) / "release.md"

def create_embed():
    # Get release notes
    release_notes = ""
    if release_file.exists():
        with open(release_file, 'r', encoding='utf-8') as f:
            release_notes = f.read().strip()

    # Create embed
    embed = {
        "title": f"New Release {TAG}",
        "url": f"https://github.com/FakeErrorX/ErrorX/releases/tag/{TAG}",
        "color": 0x00ff00,  # Green for release
        "timestamp": datetime.utcnow().isoformat(),
        "fields": []
    }

    # Split release notes into chunks due to Discord's field value limit (1024 chars)
    if release_notes:
        chunks = [release_notes[i:i+1024] for i in range(0, len(release_notes), 1024)]
        for i, chunk in enumerate(chunks):
            embed["fields"].append({
                "name": "Changelog" if i == 0 else "Changelog (continued)",
                "value": chunk
            })

    # Add download link
    embed["fields"].append({
        "name": "Download",
        "value": f"[GitHub Releases](https://github.com/FakeErrorX/ErrorX/releases/tag/{TAG})",
        "inline": True
    })

    return embed

def send_to_discord():
    embed = create_embed()
    
    payload = {
        "embeds": [embed]
    }
    
    response = requests.post(DISCORD_WEBHOOK_URL, json=payload)
    if response.status_code != 204:
        print(f"Error sending message: {response.status_code}")
        print(response.text)
        return
    print("Successfully sent release notification to Discord")

if __name__ == "__main__":
    if not DISCORD_WEBHOOK_URL:
        print("Error: DISCORD_WEBHOOK_URL environment variable not set")
        exit(1)
        
    send_to_discord() 