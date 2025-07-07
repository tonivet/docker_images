from django.contrib import messages
from django.contrib.auth import authenticate, login
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django.contrib.auth.models import User
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import get_object_or_404, redirect, render
from django.views.generic import CreateView, UpdateView
from django.urls import reverse_lazy

from .forms import SignUpForm, UserUpdateForm


class SignUpView(CreateView):
    form_class = UserCreationForm
    success_url = reverse_lazy("login")
    template_name = "registration/signup.html"


class UserEditView(LoginRequiredMixin, UpdateView):
    form_class = UserUpdateForm
    template_name = 'registration/edit_profile.html'
    success_url = reverse_lazy('home')

    def get_object(self):
        return self.request.user
    
    def post(self, request):
        user = get_object_or_404(User, pk=request.user.id)
        form = UserUpdateForm(request.POST, instance=user)
        if form.is_valid():
            if User.objects.exclude(id=request.user.id).filter(email=form.cleaned_data['email']):
                messages.error(request, "A user with this email already exist!")
                return render(request, 'registration/edit_profile.html', {'form':form })
            form.save()
            return redirect('home')
        form = UserUpdateForm()
        return render(request, 'registration/edit_profile.html', {'form':form })


def signup(request):
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            if User.objects.filter(email=form.cleaned_data['email']):
                messages.error(request, "A user with this email already exist!")
                return render(request, 'registration/signup.html', {'form':form })
            form.save()
            # Authenticate and login
            username = form.cleaned_data['username']
            password = form.cleaned_data['password1']
            user = authenticate(username=username, password=password)
            login(request, user)
            return redirect('home')
        
    else:
        form = SignUpForm()
        return render(request, 'registration/signup.html', {'form':form })
    return render(request, 'registration/signup.html', {'form':form })


