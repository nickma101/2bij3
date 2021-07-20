from app import app
from flask import jsonify, request, Blueprint
from app import elastic

from http import HTTPStatus

from app.elastic import User, hash_password

app_users = Blueprint('app_users', __name__)

@app.route("/users", methods=['POST'])
def create_user():
    """
    Create a new user. Request body should be a json with username, email, and password
    """
    data = request.get_json(force=True)
    if User.select().where(User.email == data['email']).exists():
        return bad_request("User {} already exists".format(data['email']))
    u = auth.create_user(username=data['username'], email=data['email'], password=data['password'])
    return jsonify({"id": u.id, "email": u.email}), HTTPStatus.CREATED
