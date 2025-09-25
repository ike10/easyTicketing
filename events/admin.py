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
