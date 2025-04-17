import os
import requests
from pathlib import Path
from datetime import datetime

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
TAG = os.getenv("TAG")
IS_STABLE = "-" not in TAG
release_file = Path(os.getcwd()) / "release.md"

def create_embed():
    # Get release notes
    release_notes = ""
    if release_file.exists():
        with open(release_file, 'r', encoding='utf-8') as f:
            changelog = f.read().strip()
            # Format changelog entries
            changelog_lines = changelog.split('\n')
            formatted_lines = []
            for line in changelog_lines:
                if line.startswith('- '):
                    formatted_lines.append('💫 ' + line[2:])  # Using sparkles for bullet points
                else:
                    formatted_lines.append(line)
            release_notes = '\n'.join(formatted_lines)

    # Create embed with modern styling
    embed = {
        "title": f"{'🌟' if IS_STABLE else '⭐'} ErrorX {TAG}",
        "description": "Experience the next level of error handling",
        "url": f"https://github.com/FakeErrorX/ErrorX/releases/tag/{TAG}",
        "color": 0x58b9ff if IS_STABLE else 0xf1c40f,  # Blue for stable, yellow for development
        "timestamp": datetime.utcnow().isoformat(),
        "fields": [],
        "thumbnail": {
            "url": "https://raw.githubusercontent.com/FakeErrorX/ErrorX/main/assets/icon/icon.png"
        },
        "footer": {
            "text": f"{'Stable' if IS_STABLE else 'Development'} Release • ErrorX Team",
            "icon_url": "https://raw.githubusercontent.com/FakeErrorX/ErrorX/main/assets/icon/icon.png"
        }
    }

    # Add release type with fancy formatting
    release_type = "🎯 Production Ready" if IS_STABLE else "🔧 Development Build"
    embed["fields"].append({
        "name": "📊 Release Status",
        "value": f"{release_type}\n{'🟢 Stable Channel' if IS_STABLE else '🟡 Preview Channel'}",
        "inline": True
    })

    # Add download section
    embed["fields"].append({
        "name": "🔗 Quick Links",
        "value": (
            f"[📥 Download Release](https://github.com/FakeErrorX/ErrorX/releases/tag/{TAG})\n"
            "[📚 Documentation](https://github.com/FakeErrorX/ErrorX/wiki)\n"
            "[🐛 Report Issues](https://github.com/FakeErrorX/ErrorX/issues)"
        ),
        "inline": True
    })

    # Add empty field for better layout
    embed["fields"].append({
        "name": "\u200b",
        "value": "\u200b",
        "inline": True
    })

    # Add changelog if available, split into chunks if needed
    if release_notes:
        chunks = [release_notes[i:i+1024] for i in range(0, len(release_notes), 1024)]
        for i, chunk in enumerate(chunks):
            embed["fields"].append({
                "name": f"{'🎉 What\'s New' if i == 0 else '📝 Changelog (continued)'}",
                "value": chunk,
                "inline": False
            })

    return embed

def send_to_discord():
    embed = create_embed()
    
    payload = {
        "content": "📢 **New ErrorX Release Available!**",
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
