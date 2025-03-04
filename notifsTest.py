import re

def extract_usernames(notification):
    """Extract usernames from a notification string."""
    match = re.match(r"^([\w\d_.]+(?:, [\w\d_.]+)*)", notification)
    if match:
        usernames = match.group(1)
        return [u.strip() for u in re.split(r", | and ", usernames)]  # Split on commas & 'and'
    return []
