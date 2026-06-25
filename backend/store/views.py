from django.shortcuts import render
from django.http import JsonResponse
from .models import Product

def product_list(request):
    products = Product.objects.all()
    return render(request, 'store/products.html', {'products': products})



def health_check(request):
    return JsonResponse({"status": "ok"})


from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import DocumentSerializer


class DocumentUploadAPIView(APIView):
    def post(self, request):
        serializer = DocumentSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save()
            return Response(
                {
                    "message": "File uploaded successfully",
                    "data": serializer.data
                },
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )