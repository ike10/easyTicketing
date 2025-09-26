# easyTicketing 

Lightweight Python Django app for event listing and ticket booking (SQLite, Bootstrap 5, optional Zendesk Garden styling).
Project for Advanced Programming (CPE 811).

Student Name: Oche Emmanuel Ike
Student ID: 242220011
Department: Computer Engineering (M.Eng) 

## Overview and Documentation

easyTicketing is a small Django scaffold containing:

- Project: `ticketsite`
- App: `events`
- Features: event list/detail, ticket booking (codes), admin, authentication (login, logout, signup)
- Frontend: Bootstrap 5 + small design system CSS and click-to-copy JS for ticket codes

This README explains how to run, test, and prepare the project for GitHub.

---

## Requirements

- Python 3.10 — 3.13
- pip
- Git (for uploading to GitHub)
- Recommended on Windows: use WSL or PowerShell

---

## Quick start (Linux / macOS / WSL)

1. Create & activate virtualenv

```bash
python3 -m venv venv
source venv/bin/activate
```

2. Install dependencies

```bash
pip install --upgrade pip setuptools wheel
pip install "Django==5.2.6"
```

3. Apply migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

4. Create superuser (admin)

```bash
python manage.py createsuperuser
```

5. (Optional) Create a sample event

```bash
python manage.py shell -c "from events.models import Event; from django.utils import timezone; Event.objects.get_or_create(slug='sample-event', defaults=dict(title='Sample Event', start_time=timezone.now(), total_tickets=50, price=0, venue='Online', description='Created by setup'))"
```

6. Run development server

```bash
python manage.py runserver
```

Open: http://127.0.0.1:8000/ — admin: http://127.0.0.1:8000/admin/

---

## Quick start (Windows PowerShell / CMD)

PowerShell:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install --upgrade pip setuptools wheel
pip install "Django==5.2.6"
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

CMD:

```cmd
python -m venv venv
venv\Scripts\activate.bat
pip install --upgrade pip setuptools wheel
pip install "Django==5.2.6"
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

---

## Authentication & templates notes

- Auth URLs are mounted under `/accounts/` using `django.contrib.auth.urls`.
  - Login: `/accounts/login/`
  - Logout: `/accounts/logout/` (logout implemented as POST for safety)
  - Signup: `/accounts/signup/` (custom signup view)
- The login/signup templates use a small helper filter `add_class` in `events/templatetags/form_tags.py`. If you get `Invalid filter: 'add_class'`:
  - Ensure `events` is listed in `INSTALLED_APPS` in `ticketsite/settings.py`.
  - Ensure `events/templatetags/__init__.py` and `events/templatetags/form_tags.py` exist.
  - Templates must include `{% load form_tags %}` at the top.
  - Restart the dev server after adding templatetags.

---

## Important files

- `ticketsite/settings.py` — project settings
- `events/models.py` — Event and Ticket models
- `events/views.py` — core views (list, detail, booking, signup)
- `events/urls.py` — app routes
- `templates/base.html` — shared layout and nav
- `events/templates/events/*` — event templates
- `templates/registration/*` — auth templates (login, signup)
- `static/css/main.css`, `static/js/main.js` — design system & clipboard behavior
- `events/templatetags/form_tags.py` — `add_class` filter

---

## Booking and ticket behavior

- Booking form submits purchaser name, email, and quantity.
- Generated ticket codes are shown on the booking success page; codes are clickable for copy-to-clipboard in modern browsers.
- Tickets are stored in the `Ticket` model; you can extend with payment, email, or check-in flows.

---

## Running tests

Run Django tests:

```bash
python manage.py test
```

---

## Prepare for GitHub

Recommended `.gitignore` content:

```text
venv/
db.sqlite3
*.pyc
__pycache__/
.env
.DS_Store
.vscode/
```

Create requirements:

```bash
pip freeze > requirements.txt
# or pin:
echo "Django==5.2.6" > requirements.txt
```

Initialize git and push:

```bash
git init
git add .
git commit -m "Initial commit - easyTicketing"
git remote add origin <your-git-url>
git branch -M main
git push -u origin main
```

---

## Deployment notes

- Use PostgreSQL or MySQL in production (not SQLite).
- Set `DEBUG = False`, configure `SECRET_KEY`, and populate `ALLOWED_HOSTS`.
- Run `python manage.py collectstatic` and serve static files via your web server.
- Use a WSGI/ASGI server (gunicorn/uvicorn) behind a reverse proxy (nginx) and enable HTTPS.

---

## Troubleshooting

- Template parse errors: check `{% load ... %}` lines and templatetag locations.
- `Invalid filter: 'add_class'`: see Authentication & templates notes above.
- Clipboard copy may require HTTPS or localhost in some browsers.
- If migrations fail, run `python manage.py makemigrations events` then `migrate`.

---

## Extending the project ideas

- Add payment integration (Stripe/PayPal).
- Send booking confirmation emails.
- Implement ticket check-in and `Ticket.is_used` updates.
- Export reports (CSV) and add admin dashboards.
