from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from dotenv import load_dotenv
import os
import pickle
import time
import gc

load_dotenv()

def get_screenshot():
    print("function ran")
    cookie_file = "instagram_cookies.pkl"

    chrome_options = Options()
    chrome_options.binary_location = os.getenv("CHROME_BINARY_PATH")
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=1920,1080")  
    chrome_options.add_argument("--disable-gpu")  
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-features=VizDisplayCompositor")
    chrome_options.add_argument("--blink-settings=imagesEnabled=false")  # Reduce memory usage

    service = Service(os.getenv("CHROMEDRIVER_PATH"))
    print("Initializing WebDriver...")
    driver = webdriver.Chrome(service=service, options=chrome_options)

    try:
        driver.get("https://instagram.com/accounts/login")
        WebDriverWait(driver, 20).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "main[role='main']"))
        )

        while True: 
            time.sleep(1)  # Prevent CPU overuse

            if os.path.exists(cookie_file):
                driver.delete_all_cookies()  # Clear old cookies
                cookies = pickle.load(open(cookie_file, "rb"))
                for cookie in cookies:
                    driver.add_cookie(cookie)

                try:
                    driver.get("https://instagram.com/notifications")
                    WebDriverWait(driver, 20).until(
                        EC.presence_of_element_located((By.CSS_SELECTOR, "div[role='heading']"))
                    )
                    print("taking screenshot...")
                    driver.save_screenshot("screenshots/notifs_screenshot.png")
                    break
                except Exception as e:
                    continue
            
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

                    try:
                        save_button = WebDriverWait(driver, 15).until(
                            EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Save')]"))
                        )
                        save_button.click()
                        time.sleep(8)
                    except Exception as e:
                        print(e)
                    
                    pickle.dump(driver.get_cookies(), open(cookie_file, "wb"))
                    print("cookies saved.")

    finally:
        driver.quit()  # Ensure WebDriver quits
        del driver
        gc.collect()  # Free up memory

    return "screenshots/notifs_screenshot.png"

if __name__ == "__main__":
    get_screenshot()
