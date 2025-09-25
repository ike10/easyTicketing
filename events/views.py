from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django import forms
from django.contrib.auth import login as auth_login
from django.contrib.auth.forms import UserCreationForm
from .models import Event, Ticket

def event_list(request):
    events = Event.objects.order_by('start_time')
    return render(request, 'events/event_list.html', {'events': events})

def event_detail(request, slug):
    event = get_object_or_404(Event, slug=slug)
    return render(request, 'events/event_detail.html', {'event': event})

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

        return render(request, 'events/booking_success.html', {'codes': codes, 'event': event})

    return redirect(event.get_absolute_url())

# Signup form + view
class SignupForm(UserCreationForm):
    email = forms.EmailField(required=False)

    class Meta(UserCreationForm.Meta):
        fields = ("username", "email",)

def signup(request):
    if request.user.is_authenticated:
        return redirect('event_list')
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user = form.save()
            # ensure email saved if provided
            email = form.cleaned_data.get('email')
            if email:
                user.email = email
                user.save()
            auth_login(request, user)
            next_url = request.POST.get('next') or '/'
            return redirect(next_url)
    else:
        form = SignupForm()
    return render(request, 'registration/signup.html', {'form': form})
