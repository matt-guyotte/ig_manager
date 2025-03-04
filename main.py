from flask import Flask, redirect, render_template, request
app = Flask(__name__)

from automate_insta import check_notifications
from db_config import db_config
from add_to_db import add_to_db
from get_notifs import get_notifs
from delete_notif import delete_notif

@app.route("/")
def home():
    connection = db_config()
    notifs = get_notifs(connection)
    return render_template("index.html", items=notifs)

@app.route("/delete_notif", methods=["POST"])
def delete_notification(): 
    data = request.json
    app.logger.info(data)
    connection = db_config()
    app.logger.info(data)
    delete_notif(connection, data.get("text"))
    return "0"

@app.route("/main")
def main():
    notifications = check_notifications()
    app.logger.info("notifications ran")
    connection = db_config()
    add_to_db(notifications, connection)
    notifs = get_notifs(connection)
    connection.close()
    app.logger.info("add to db ran")
    app.logger.info(notifications)
    return redirect("/")
    
if __name__ == "__main__":
    app.run(debug=True)
