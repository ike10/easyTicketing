#!/usr/bin/env bash
# setup_ticket_project.sh
# Creates a Django (SQLite) project scaffold for an Event Ticketing & Booking website
# - Python (Django 5.2.6 LTS)
# - Database: SQLite (default)
# - Styling: Bootstrap 5 + optional Zendesk Garden (via jsDelivr)
# Usage: chmod +x setup_ticket_project.sh && ./setup_ticket_project.sh
# This script is written for Unix-like systems (macOS / Linux). Windows users: run similar commands in PowerShell or WSL.

set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="ticketsite"
APP_NAME="events"
DJANGO_VERSION="5.2.6"
VENV_DIR="venv"
PYTHON_BIN="python3"

echo "\n==> Starting setup for ${PROJECT_NAME} (app: ${APP_NAME})"

# 1) Check python
if ! command -v ${PYTHON_BIN} >/dev/null 2>&1; then
  echo "ERROR: ${PYTHON_BIN} not found. Install Python 3.10+ (Django 5.2 requires Python 3.10-3.13)."
  exit 1
fi

if ! ${PYTHON_BIN} -c "import sys; sys.exit(0) if sys.version_info >= (3,10) else sys.exit(1)"; then
  echo "ERROR: Python 3.10 or newer is required. Your ${PYTHON_BIN} is older."
  ${PYTHON_BIN} --version || true
  exit 1
fi

# 2) Create virtualenv
echo "==> Creating virtual environment in ./${VENV_DIR}"
${PYTHON_BIN} -m venv ${VENV_DIR}
# shellcheck source=/dev/null
source ${VENV_DIR}/bin/activate

echo "==> Upgrading pip and installing Django ${DJANGO_VERSION}"
python -m pip install --upgrade pip setuptools wheel
pip install "Django==${DJANGO_VERSION}"

# 3) Start Django project & app
if [ -d "${PROJECT_NAME}" ]; then
  echo "Note: directory ${PROJECT_NAME} already exists — skipping startproject step."
else
  echo "==> Creating Django project: ${PROJECT_NAME}"
  django-admin startproject ${PROJECT_NAME} .
fi

if [ -d "${APP_NAME}" ]; then
  echo "Note: app ${APP_NAME} already exists — skipping startapp step."
else
  echo "==> Creating Django app: ${APP_NAME}"
  python manage.py startapp ${APP_NAME}
fi

# 4) Create templates & static dirs
mkdir -p templates ${APP_NAME}/templates/${APP_NAME} static/css static/js

# 5) Create app models, views, urls, admin and templates
cat > ${APP_NAME}/models.py <<PY
from django.db import models
from django.urls import reverse
from django.conf import settings
import uuid

class Event(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    venue = models.CharField(max_length=200, blank=True)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(null=True, blank=True)
    total_tickets = models.PositiveIntegerField(default=100)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def available_tickets(self):
        # tickets sold are Ticket objects linked to this event
        return self.total_tickets - self.ticket_set.count()

    def get_absolute_url(self):
        return reverse('event_detail', args=[self.slug])

    def __str__(self):
        return self.title


def generate_code():
    # short unique-ish code for tickets
    return uuid.uuid4().hex[:12].upper()

class Ticket(models.Model):
    code = models.CharField(max_length=20, unique=True, default=generate_code)
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
    purchaser_name = models.CharField(max_length=200, blank=True)
    purchaser_email = models.EmailField(blank=True)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.code} - {self.event.title}"
PY

cat > ${APP_NAME}/admin.py <<PY
from django.contrib import admin
from .models import Event, Ticket

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    prepopulated_fields = {"slug": ("title",)}
    list_display = ('title','start_time','venue','total_tickets')

@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ('code','event','purchaser_name','purchaser_email','is_used','created_at')
    readonly_fields = ('code','created_at')
PY

cat > ${APP_NAME}/views.py <<PY
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from .models import Event, Ticket

def event_list(request):
    events = Event.objects.order_by('start_time')
    return render(request, '${APP_NAME}/event_list.html', {'events': events})

def event_detail(request, slug):
    event = get_object_or_404(Event, slug=slug)
    return render(request, '${APP_NAME}/event_detail.html', {'event': event})

def book_ticket(request, slug):
    event = get_object_or_404(Event, slug=slug)
    if request.method == 'POST':
        name = request.POST.get('name', '')
        email = request.POST.get('email', '')
        try:
            qty = int(request.POST.get('quantity', '1'))
        except ValueError:
            messages.error(request, 'Invalid quantity')
            return redirect(event.get_absolute_url())

        available = event.available_tickets()
        if qty < 1 or qty > available:
            messages.error(request, 'Invalid quantity selected')
            return redirect(event.get_absolute_url())

        codes = []
        for _ in range(qty):
            ticket = Ticket.objects.create(
                event=event,
                user=request.user if request.user.is_authenticated else None,
                purchaser_name=name,
                purchaser_email=email
            )
            codes.append(ticket.code)

        return render(request, '${APP_NAME}/booking_success.html', {'codes': codes, 'event': event})

    return redirect(event.get_absolute_url())
PY

cat > ${APP_NAME}/urls.py <<PY
from django.urls import path
from . import views

urlpatterns = [
    path('', views.event_list, name='event_list'),
    path('event/<slug:slug>/', views.event_detail, name='event_detail'),
    path('event/<slug:slug>/book/', views.book_ticket, name='book_ticket'),
]
PY

# 6) Update project urls.py to include app urls
cat > ${PROJECT_NAME}/urls.py <<PY
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('${APP_NAME}.urls')),
]
PY

# 7) Tweak settings.py: add app to INSTALLED_APPS, set templates dir and staticfiles dir
SETTINGS_FILE="${PROJECT_NAME}/settings.py"
python - <<PY
from pathlib import Path
p = Path('')
settings_path = p / '${SETTINGS_FILE}'
s = settings_path.read_text()

# 1) Add app to INSTALLED_APPS if missing
if "'${APP_NAME}'" not in s:
    s = s.replace("INSTALLED_APPS = [", "INSTALLED_APPS = [\n    '${APP_NAME}',")

# 2) Ensure templates DIRS points to BASE_DIR / 'templates'
s = s.replace("'DIRS': [],", "'DIRS': [BASE_DIR / 'templates'],")

# 3) Add STATICFILES_DIRS after STATIC_URL definition if not present
if 'STATICFILES_DIRS' not in s:
    if "STATIC_URL = 'static/'" in s:
        s = s.replace("STATIC_URL = 'static/'", "STATIC_URL = 'static/'\n\nSTATICFILES_DIRS = [BASE_DIR / 'static']")

# 4) Convenience redirects for auth
if 'LOGIN_REDIRECT_URL' not in s:
    s = s + "\nLOGIN_REDIRECT_URL = '/'\nLOGOUT_REDIRECT_URL = '/'\n"

settings_path.write_text(s)
print('Updated', settings_path)
PY

# 8) Create basic templates (base, list, detail, success)
cat > templates/base.html <<'HTML'
{% raw %}{% load static %}
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{% block title %}Event Tickets{% endblock %}</title>
    <!-- Bootstrap CSS (jsDelivr) -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Optional: Zendesk Garden CSS via jsDelivr (see docs) -->
    <!-- Example: <link rel="stylesheet" href="https://cdn.jsdelivr.net/combine/npm/@zendeskgarden/css-bedrock@10.0.1,npm/@zendeskgarden/css-forms@8.0.0"> -->
    <link rel="stylesheet" href="{% static 'css/main.css' %}">
  </head>
  <body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light mb-4">
      <div class="container">
        <a class="navbar-brand" href="/">Ticketing</a>
        <div>
          {% if user.is_authenticated %}
            <span class="me-2">Hello, {{ user.username }}</span>
            <a class="btn btn-outline-secondary btn-sm" href="{% url 'logout' %}">Logout</a>
          {% else %}
            <a class="btn btn-primary btn-sm" href="{% url 'login' %}">Login</a>
          {% endif %}
        </div>
      </div>
    </nav>

    <main class="container">
      {% if messages %}
        {% for message in messages %}
          <div class="alert alert-{{ message.tags }}">{{ message }}</div>
        {% endfor %}
      {% endif %}
      {% block content %}{% endblock %}
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>{% endraw %}
HTML

cat > ${APP_NAME}/templates/${APP_NAME}/event_list.html <<'HTML'
{% raw %}{% extends 'base.html' %}
{% block title %}Events{% endblock %}
{% block content %}
  <h1>Upcoming events</h1>
  <div class="row">
    {% for event in events %}
      <div class="col-md-6 mb-3">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">{{ event.title }}</h5>
            <p class="card-text">{{ event.description|truncatechars:120 }}</p>
            <p class="small">When: {{ event.start_time }}</p>
            <a href="{{ event.get_absolute_url }}" class="btn btn-primary">Details &amp; book</a>
          </div>
        </div>
      </div>
    {% empty %}
      <p>No events yet.</p>
    {% endfor %}
  </div>
{% endblock %}{% endraw %}
HTML

cat > ${APP_NAME}/templates/${APP_NAME}/event_detail.html <<'HTML'
{% raw %}{% extends 'base.html' %}
{% block title %}{{ event.title }}{% endblock %}
{% block content %}
  <h1>{{ event.title }}</h1>
  <p>{{ event.description }}</p>
  <p><strong>Venue:</strong> {{ event.venue }}</p>
  <p><strong>Starts:</strong> {{ event.start_time }}</p>
  <p><strong>Available tickets:</strong> {{ event.available_tickets }}</p>

  <h3>Book ticket</h3>
  <form method="post" action="{% url 'book_ticket' event.slug %}">
    {% csrf_token %}
    <div class="mb-3">
      <label class="form-label">Your name</label>
      <input class="form-control" name="name" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Email</label>
      <input class="form-control" name="email" type="email" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Quantity</label>
      <input class="form-control" name="quantity" type="number" min="1" max="{{ event.available_tickets }}" value="1">
    </div>
    <button class="btn btn-success" type="submit">Buy</button>
  </form>
{% endblock %}{% endraw %}
HTML

cat > ${APP_NAME}/templates/${APP_NAME}/booking_success.html <<'HTML'
{% raw %}{% extends 'base.html' %}
{% block content %}
  <h1>Booking successful</h1>
  <p>You booked ticket(s) for <strong>{{ event.title }}</strong>. Save these codes (each is one ticket):</p>
  <ul>
    {% for code in codes %}
      <li><code>{{ code }}</code></li>
    {% endfor %}
  </ul>
  <a href="/" class="btn btn-primary">Back to events</a>
{% endblock %}{% endraw %}
HTML

# 9) Create a tiny static css file
cat > static/css/main.css <<'CSS'
/* Add your site overrides here */
body { padding-bottom: 40px; }
CSS

# 10) Add urls for auth (login/logout) in project urls
python - <<PY
from pathlib import Path
p = Path('${PROJECT_NAME}/urls.py')
s = p.read_text()
# check for the import line and that auth urls are not already present
if "from django.urls import path, include" in s and "include('django.contrib.auth.urls')" not in s:
    new = "path('', include('${APP_NAME}.urls')),\n    path('accounts/', include('django.contrib.auth.urls')),"
    s = s.replace("path('', include('${APP_NAME}.urls')),", new)
    p.write_text(s)
    print('Added accounts/ auth urls')
else:
    print('Auth urls already present or unexpected urls.py format')
PY


# 11) Make migrations & migrate
echo "==> Making migrations and migrating"
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# 12) Create a sample event (optional)
python manage.py shell <<PY
from django.utils import timezone
from ${APP_NAME}.models import Event
if not Event.objects.filter(slug='sample-event').exists():
    Event.objects.create(title='Sample Event', slug='sample-event', description='A sample event created by setup script', venue='Online', start_time=timezone.now(), total_tickets=50, price=0)
    print('Created sample event: /event/sample-event/')
else:
    print('Sample event already exists')
PY

# 13) VSCode helper files
mkdir -p .vscode
cat > .vscode/launch.json <<'JSON'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Django",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/manage.py",
      "args": ["runserver", "8000"],
      "django": true
    }
  ]
}
JSON

cat > .vscode/extensions.json <<'JSON'
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "batisteo.vscode-django"
  ]
}
JSON

# 14) Final message
echo "\n==> Setup complete.
Run the development server with:\n  source ${VENV_DIR}/bin/activate\n  python manage.py runserver\n
Open http://127.0.0.1:8000/ to view the site.\n
Admin: create a superuser with:\n  python manage.py createsuperuser\n
Notes:\n- Django ${DJANGO_VERSION} (LTS) was installed.\n- Bootstrap 5 is used via CDN in templates/base.html.\n- Zendesk Garden may be included via jsDelivr (see documentation) if you want Garden components.\n"

# End
