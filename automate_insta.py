import os
import pytesseract
import cv2
import sys
import numpy as np
import re  # Import regex for better filtering
from collections import defaultdict
from PIL import Image
from dotenv import load_dotenv
load_dotenv()

from db_config import db_config
from notifsTest import extract_usernames
from check_name import check_name
from get_screenshot import get_screenshot

# Ensure console supports UTF-8 output
sys.stdout.reconfigure(encoding="utf-8")

# Set Tesseract path (update if needed)
pytesseract.pytesseract.tesseract_cmd = os.getenv("PYTESSERACT_PATH")

# UI words to filter out
UI_FILTER_WORDS = [
    "Instagram", "Home", "Search", "Explore", "Reels", "Messages",
    "Threads", "Profile", "Dashboard", "Create", "Notifications",
    "%", "@", "All Bookmarks", "Today", "New", "instagram.com/notifications", 
    "More", "Ce]", "oo AI Studio", "®", "Justagram", 
    "Justagram, (A Q ® explore", "© messages oo Al Studio", 
    "This week", "This month", "Yesterday", "Follow", "Commented", "ay", "ek"
]

# Function to check if text contains unwanted UI elements
def contains_ui_words(text):
    """Returns True if the text contains any UI word (case-insensitive)."""
    return any(re.search(rf'\b{re.escape(word)}\b', text, re.IGNORECASE) for word in UI_FILTER_WORDS)

def check_notifications():
    """Automates checking Instagram notifications, extracts text, and detects thumbnails."""
    
    screenshot_url = get_screenshot()

    # Convert to PIL format
    
    # Open the screenshot
    screenshot = Image.open(screenshot_url)

    # Crop the image (adjust left, top, right, bottom as needed)
    cropped_screenshot = screenshot.crop((900, 0, screenshot.width - 600, screenshot.height))

    # Convert to OpenCV format
    opencv_image = np.array(cropped_screenshot)

    # Convert to grayscale
    gray = cv2.cvtColor(opencv_image, cv2.COLOR_RGB2GRAY)

    # Apply thresholding (adaptive or Otsu’s)
    _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Resize for better accuracy (scale up)
    scale_factor = 2
    resized = cv2.resize(thresh, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_CUBIC)

    # Save the preprocessed image (for debugging)
    cv2.imwrite('screenshots/preprocessed_screenshot.png', resized)

    # Perform OCR with optimized parameters
    custom_config = r'--oem 3 --psm 6'
    ocr_data = pytesseract.image_to_data(resized, output_type=pytesseract.Output.DICT, config=custom_config)

    # Save the cropped screenshot (for reference)
    cropped_screenshot.save('screenshots/final_screenshot.png')

    notifications = []
    current_notification = []
    last_y = None
    y_threshold = 20 
    connection = db_config()
    
    # Group detected words by their line number
    for i, ocr_text in enumerate(ocr_data["text"]):
        text = ocr_text.strip()

        # Skip unwanted UI elements and garbage text at the beginning
        if not text or contains_ui_words(text) or not re.search(r'[a-zA-Z0-9]', text):  
            continue

        y = ocr_data["top"][i]

        # Start a new notification if there's a significant vertical gap
        if last_y is not None and abs(y - last_y) > y_threshold:
            if current_notification:  
                # Remove unwanted symbols at the beginning and end
                full_text = re.sub(r'^[^a-zA-Z0-9]+', '', " ".join(current_notification).strip())
                timestamp_remove = re.search(r"(.*?\.)\s(?:\d+[hd])?$", full_text)
                if timestamp_remove: 
                    full_text = timestamp_remove.group(1)
                if full_text:
                    notification_type = ""
                    usernames = extract_usernames(full_text)
                    if usernames:
                        if not full_text.startswith(usernames[0]):
                            full_text = full_text.split(usernames[0], 1)[1]
                        if "liked" in full_text:  
                            notification_type = "like"
                        elif "following" in full_text:
                            notification_type = "follow"
                        for i, name in enumerate(usernames):
                            if check_name(connection, name) > 0 : 
                                break
                            if i == len(usernames) - 1:
                                notifications.append({
                                    "text": full_text,
                                    "_type": notification_type,
                                    "names": usernames
                                })
            current_notification = []

        current_notification.append(text)
        last_y = y

    # Add the last notification if not empty
    if current_notification:
        full_text = re.sub(r'^[^a-zA-Z0-9]+', '', " ".join(current_notification).strip())
        timestamp_remove = re.search(r"(.*?\.)\s(?:\d+[hd])?$", full_text)
        if timestamp_remove:
            full_text = timestamp_remove.group(1)
        if full_text:
            notification_type = ""
            usernames = extract_usernames(full_text)
            if usernames:
                # Check if the first username is actually in the text
                if not full_text.startswith(usernames[0]):
                    full_text = full_text.split(usernames[0], 1)[1]
                if "liked" in full_text:  
                    notification_type = "like"
                elif "following" in full_text:
                    notification_type = "follow"
                for i, name in enumerate(usernames):
                    if check_name(connection, name) > 0 : 
                        break
                    if i == len(usernames) - 1:
                        notifications.append({
                            "text": full_text,
                            "_type": notification_type,
                            "names": usernames
                        })

    # **Final Cleanup: Remove UI elements & small fragments**
    cleaned_notifications = []
    buffer = ""

    for notification in notifications:
        n = notification["text"].strip()
        print(n)

        # Apply UI filtering again at full notification level
        if not n or contains_ui_words(n) or n.lower() == "follow":  
            continue

        # If the notification looks incomplete, store it in buffer
        if len(n.split()) < 4:  
            buffer += " " + n
        else:
            # If there's a buffer, merge it with the new notification
            if buffer:
                cleaned_notifications.append(
                    {
                        "text": buffer.strip() + " " + n,
                        "_type": notification["_type"], 
                        "names": notification["names"]
                    })
                buffer = ""
            else:
                cleaned_notifications.append(
                    {
                        "text": n,
                        "_type": notification["_type"],
                        "names": notification["names"]
                    })

    # Print notifications
    print("\n📌 **Instagram Notifications:**\n")
    for i, notification in enumerate(cleaned_notifications, 1):
        if i == 0:
            notification['text'] = notification.split(" ", 1)[1]
        print(f"{i}. {notification['text'], notification['_type']}")

    connection.close()
    return cleaned_notifications

if __name__ == "__main__":
    check_notifications()
