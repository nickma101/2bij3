import logging

def initialize_if_needed():
    from app.user_auth import User
    db.indices.create("users")
