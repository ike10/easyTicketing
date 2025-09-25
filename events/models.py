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
