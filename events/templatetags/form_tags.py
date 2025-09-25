from django import template

register = template.Library()

@register.filter(name='add_class')
def add_class(bound_field, css_class):
    """
    Usage: {{ form.field|add_class:"form-control" }}
    Returns the field rendered with the extra CSS class appended.
    """
    try:
        widget = bound_field.field.widget
        existing = widget.attrs.get('class', '')
        classes = (existing + ' ' + css_class).strip()
        return bound_field.as_widget(attrs={"class": classes})
    except Exception:
        return bound_field