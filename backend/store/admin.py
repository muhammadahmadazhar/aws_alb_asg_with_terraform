from django.contrib import admin
from .models import Product
from .models import Document


# Register your models here.

admin.site.register(Product)

@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "file", "uploaded_at")
    search_fields = ("title",)
    list_filter = ("uploaded_at",)
    ordering = ("-uploaded_at",)