# ig_manager
A notification manager for Instagram.

This is designed to solve the problem of instagram grouping notifications of who liked a post together when your following gets large enough. 

It does this by taking screenshots of your notification page at regular intervals (every 10 minutes by default), and converts it into notifications like how you would see on your notification screen. 

Due to it's frequency, it allows you to see every individual user who interacts with your posts, allowing easier outreach.

# INSTALL INSTRUCTIONS:

This is meant to be hosted on an ubuntu instance, with the user's choice of cloud or physical server. This will work the same on either. 

* If you are planning on using a domain, make sure you have one available before starting this process. This can also be used on localhost if you're looking to play around with the app.

1. Run "git clone https://github.com/matt-guyotte/ig_manager" in your ubuntu instance's home/ubuntu/ directory. If your username is something different than ubuntu, swap your username out for it. 

2. Run "cd ig_manager/shell_scripts". You will be using the app_setup.sh to configure the app. 

3. Make the script executable by running "chmod +x app_setup.sh". 

4. Run the command "./app_setup.sh" in the shell_scripts directory. You will be creating the username and password to your postgresql user here, so save it if you would like to play around with the database later. Also have your domain and instagram credentials ready. 

* If you want to use this on localhost, just type in "localhost" when prompted for your domain.

The script will now create a:
    .env,
    postgresql db with provided credentials,
    systemctl ig_manager service,
    nginx service,
    and cron file to run the app every 10 minutes. 


* If you would like to use https, and are running your app on 0.0.0.0/0 (no ip restriction), the add_https.sh will allow you to run the Let's Encrypt service to set it up for you. Make sure to run "chmod +x add_https.sh" to make it executable. If you are restricting ips, you will need to configure this manually.

# OPEN SOURCE CONTRIBUTIONS:

Feel free to alter this code however you see fit. I look at pull requests infrequently, but you can reach me at webdevelopmentmg@gmail.com if there is something you want me to look at. 
