from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from dotenv import load_dotenv
load_dotenv()

import os
import pickle
import time

def get_screenshot():
    print("function ran")
    cookie_file = "instagram_cookies.pkl"
    # Unique user data dir based on time and PID
    user_data_dir = f"/home/ubuntu/chrome-user-data-{int(time.time())}-{os.getpid()}"

    # Cleanup any existing directories (if any) before proceeding
    if os.path.exists(user_data_dir):
        print(f"Cleaning up existing user data directory: {user_data_dir}")
        # Remove any existing directory
        os.system(f"rm -rf {user_data_dir}")

    chrome_options = Options()
    chrome_options.binary_location = os.getenv("CHROME_BINARY_PATH")
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=1920,1080")  # Set window size
    chrome_options.add_argument("--disable-gpu")  # Disable GPU (sometimes needed for headless mode)
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument(f"--user-data-dir={user_data_dir}")

    service = Service(os.getenv("CHROMEDRIVER_PATH"))
    print("Initializing WebDriver...")
    driver = webdriver.Chrome(service=service, options=chrome_options)

    driver.get("https://instagram.com/accounts/login")
    time.sleep(10)
    
    if os.path.exists(cookie_file):
        cookies = pickle.load(open(cookie_file, "rb"))
        for cookie in cookies:
            driver.add_cookie(cookie)
        
        driver.get("https://instagram.com/notifications")
        time.sleep(10)
        
        #If instagram asks to save login information
        save_button = None
        try:
            save_button = driver.find_element(By.XPATH, "//button[text()='Save']")
        except Exception as e:
            print(e)
        if save_button:
            save_button.click()
        #this is ran upon redirect back to login
        if 'notifications' not in driver.current_url:
            os.remove(cookie_file)
            return get_screenshot()
    else: 
        if "accounts/login" in driver.current_url:
            username = driver.find_element(By.NAME, "username")
            password = driver.find_element(By.NAME, "password")
            username.send_keys(os.getenv("INSTA_USER"))
            password.send_keys(os.getenv("INSTA_PASS"))
            driver.save_screenshot("screenshots/info_entered.png")

            login_button = driver.find_element(By.XPATH, "//button[@type='submit']")
            login_button.click()
            driver.save_screenshot("screenshots/button_clicked.png")
            time.sleep(10)
            driver.save_screenshot("screenshots/login_complete.png")
            pickle.dump(driver.get_cookies(), open(cookie_file, "wb"))
            print("cookies saved.")
            return get_screenshot()

    print("taking screenshot...")
    driver.save_screenshot("screenshots/notifs_screenshot.png")

    driver.quit()
    return "screenshots/notifs_screenshot.png"

if __name__ == "__main__":
    get_screenshot()
