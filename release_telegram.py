import os
import requests

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TAG = os.getenv("TAG")
IS_STABLE = "-" not in TAG
CHAT_ID = "@ErrorX_BD"
API_URL = f"http://localhost:8081/bot{TELEGRAM_BOT_TOKEN}/sendMessage"

release = os.path.join(os.getcwd(), "release.md")

def create_message():
    # Create a modern formatted message
    message_parts = []
    
    # Header with fancy formatting
    message_parts.append(f"{'🌟' if IS_STABLE else '⭐'} *ErrorX {TAG}*")
    message_parts.append("_Experience the next level of error handling_\n")
    
    # Release status section
    status_emoji = "🟢" if IS_STABLE else "🟡"
    release_type = "Production Ready" if IS_STABLE else "Development Build"
    message_parts.append(f"*📊 Release Status*")
    message_parts.append(f"{status_emoji} Channel: {'Stable' if IS_STABLE else 'Preview'}")
    message_parts.append(f"🎯 Type: {release_type}\n")
    
    # Quick links section
    message_parts.append("*🔗 Quick Links*")
    message_parts.append(f"📥 [Download Release](https://github.com/FakeErrorX/ErrorX/releases/tag/{TAG})")
    message_parts.append("📚 [Documentation](https://github.com/FakeErrorX/ErrorX/wiki)")
    message_parts.append("🐛 [Report Issues](https://github.com/FakeErrorX/ErrorX/issues)\n")
    
    # Add changelog if available
    if os.path.exists(release):
        message_parts.append("*🎉 What's New*")
        with open(release, 'r') as f:
            changelog = f.read().strip()
            # Format changelog entries
            changelog_lines = changelog.split('\n')
            formatted_lines = []
            for line in changelog_lines:
                if line.startswith('- '):
                    formatted_lines.append('💫 ' + line[2:])  # Using sparkles for bullet points
                else:
                    formatted_lines.append(line)
            message_parts.append('\n'.join(formatted_lines))
    
    # Footer
    message_parts.append("\n🔔 _Stay updated with ErrorX releases!_")
    
    return '\n'.join(message_parts)

def send_to_telegram():
    response = requests.post(
        API_URL,
        data={
            "chat_id": CHAT_ID,
            "text": create_message(),
            "parse_mode": "Markdown",
            "disable_web_page_preview": False  # Enable link preview for GitHub
        }
    )
    
    print("Response JSON:", response.json())

if __name__ == "__main__":
    if not TELEGRAM_BOT_TOKEN:
        print("Error: TELEGRAM_BOT_TOKEN environment variable not set")
        exit(1)
        
    send_to_telegram()
