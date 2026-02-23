from django.shortcuts import render
from django.http import JsonResponse
from .models import Product

def product_list(request):
    products = Product.objects.all()
    return render(request, 'store/products.html', {'products': products})



def health_check(request):
    return JsonResponse({"status": "ok"})