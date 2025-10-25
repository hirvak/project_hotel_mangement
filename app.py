# app.py
from flask import Flask, request, jsonify, session, redirect, url_for, flash
from flask_session import Session
from werkzeug.security import generate_password_hash, check_password_hash
from db_config import get_db_connection
from functools import wraps
from datetime import datetime

app = Flask(_name_)
app.secret_key = 'replace-with-a-secure-random-key'  # replace before production
app.config['SESSION_TYPE'] = 'filesystem'
Session(app)

# ---------------- Helper DB functions ----------------
def query_db(query, args=None, one=False):
    """
    Run SELECT queries and return results as list of dicts (dictionary=True)
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(query, args or ())
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    if one:
        return rows[0] if rows else None
    return rows

def execute_db(query, args=None):
    """
    Run INSERT/UPDATE/DELETE queries. Returns lastrowid.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(query, args or ())
    conn.commit()
    lastrow = cursor.lastrowid
    cursor.close()
    conn.close()
    return lastrow

def call_proc(proc_name, args=None):
    """
    Call stored procedure (no result expected here).
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.callproc(proc_name, args or ())
    conn.commit()
    cursor.close()
    conn.close()

# ---------------- Auth & Session ----------------
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated

def role_required(role):
    def wrapper(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if session.get('role') != role:
                return jsonify({'error': 'Unauthorized - role required: {}'.format(role)}), 403
            return f(*args, **kwargs)
        return decorated
    return wrapper

# ---------------- Basic routes ----------------
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'time': datetime.utcnow().isoformat()})

@app.route('/', methods=['GET'])
def index():
    if 'username' in session:
        return jsonify({
            'message': f"Logged in as {session.get('username')}",
            'user_id': session.get('user_id'),
            'role': session.get('role')
        })
    return jsonify({'message': 'Welcome to Hotel Management API. Use /login or /register.'})

# ---------------- Register ----------------
@app.route('/register', methods=['POST'])
def register():
    """
    Minimal register endpoint.
    Expected JSON: { "username":"", "password":"", "name":"" (optional) }
    Creates a Users row (role='guest') and a Guest row.
    """
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    name = data.get('name') or username

    if not username or not password:
        return jsonify({'error': 'username and password required'}), 400

    # Check username exists
    existing = query_db('SELECT * FROM Users WHERE username = %s', (username,), one=True)
    if existing:
        return jsonify({'error': 'username already exists'}), 409

    hashed = generate_password_hash(password)
    try:
        user_id = execute_db('INSERT INTO Users (username, password, role) VALUES (%s, %s, %s)', (username, hashed, 'guest'))
        # Create Guest minimal record
        execute_db('INSERT INTO Guest (user_id, name) VALUES (%s, %s)', (user_id, name))
        return jsonify({'message': 'Registered successfully', 'user_id': user_id}), 201
    except Exception as e:
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500

# ---------------- Login ----------------
@app.route('/login', methods=['POST'])
def login():
    """
    Expected JSON: { "username":"", "password":"" }
    """
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'username and password required'}), 400

    user = query_db('SELECT * FROM Users WHERE username = %s', (username,), one=True)
    if not user:
        return jsonify({'error': 'invalid credentials'}), 401

    # Password might be hashed. If stored plain-text (legacy), check both.
    stored = user.get('password') or ''
    password_ok = False
    try:
        password_ok = check_password_hash(stored, password)
    except Exception:
        # if stored value not a hash, fallback to direct comparison (legacy)
        password_ok = (stored == password)

    if not password_ok:
        return jsonify({'error': 'invalid credentials'}), 401

    # All good — create session
    session['user_id'] = user['user_id']
    session['username'] = user['username']
    session['role'] = user['role']
    return jsonify({'message': 'logged in', 'user_id': user['user_id'], 'role': user['role']})

# ---------------- Logout ----------------
@app.route('/logout', methods=['POST'])
@login_required
def logout():
    session.clear()
    return jsonify({'message': 'logged out'})

# ---------------- Example protected routes ----------------
@app.route('/admin/check', methods=['GET'])
@login_required
@role_required('admin')
def admin_check():
    return jsonify({'message': 'hello admin', 'username': session.get('username')})

@app.route('/guest/profile', methods=['GET'])
@login_required
@role_required('guest')
def guest_profile():
    # fetch guest record (if exists)
    g = query_db('SELECT * FROM Guest WHERE user_id = %s', (session['user_id'],), one=True)
    return jsonify({'guest': g})

# ---------------- Run ----------------
if _name_ == '_main_':
    # For initial testing, debug True is convenient. Switch off in production.
    app.run(debug=True, host='0.0.0.0', port=5000)
