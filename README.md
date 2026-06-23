# Language App — Monorepo

A full-stack language learning application built with **Angular** (frontend) and **Laravel** (backend).

## 📁 Project Structure

```
language_app/
├── frontend/          ← Angular 21 (TypeScript)
│   ├── src/
│   ├── angular.json
│   ├── package.json
│   └── tsconfig.json
│
├── backend/           ← Laravel 11 (PHP)
│   ├── app/
│   ├── routes/
│   ├── database/
│   └── composer.json
│
└── README.md
```

---

## 🚀 Getting Started

### Frontend (Angular)

```bash
cd frontend
npm install
ng serve
```

Navigate to `http://localhost:4200/`

### Backend (Laravel)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

API runs at `http://localhost:8000/`

---

## 🛠 Development

### Frontend Commands

```bash
cd frontend

# Serve (dev)
ng serve

# Build (production)
ng build

# Run tests
ng test

# Generate component
ng generate component component-name
```

### Backend Commands

```bash
cd backend

# Start dev server
php artisan serve

# Run migrations
php artisan migrate

# Generate model/controller
php artisan make:model ModelName -mcr
```

---

## 📦 Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Angular 21, TypeScript, Bootstrap 5 |
| Backend | Laravel 11, PHP |
| Database | MySQL |
| Editor | EditorJS |

---

## 🔗 Additional Resources

- [Angular CLI Docs](https://angular.dev/tools/cli)
- [Laravel Docs](https://laravel.com/docs)
