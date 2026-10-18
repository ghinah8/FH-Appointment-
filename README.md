# FH Fatima Habib — Architecture Tutoring Booking System

A responsive Arabic web application designed to simplify appointment booking and management for architecture tutoring sessions. The platform aims to provide students with an organized booking experience while allowing the tutor to manage appointments, availability, and student requests through an administrative dashboard.

## 🎯 Project Overview

**FH Fatima Habib** is being developed as a web-based appointment management system for architecture students. It is designed to streamline the scheduling process, reduce booking conflicts, and provide clear communication between students and the tutor.

The application supports Arabic and a right-to-left (RTL) interface, with a focus on usability, maintainability, and a consistent visual identity.

## ✨ Planned Features

### Student Features
- Create an account and verify an email address.
- Sign in and securely manage authentication.
- Register personal and academic information, including university and study year.
- Browse available appointment dates and time slots.
- Request tutoring appointments based on the tutor's availability.
- View appointment statuses and booking history.
- Request appointment cancellation or rescheduling.
- Receive appointment reminders and relevant notifications.

### Admin Features
- Access an administrative dashboard.
- Review, approve, or reject booking requests.
- Manage confirmed appointments.
- Configure working hours and available time slots.
- Manage holidays, schedule exceptions, and exceptional appointments.
- Review student information and booking history.
- Handle cancellation and rescheduling requests.
- Prepare WhatsApp messages for appointment-related communication.

## 🛠️ Tech Stack

- **Frontend:** Flutter Web
- **Programming Language:** Dart
- **State Management:** BLoC / Cubit
- **Backend Services:** Supabase
- **Database:** PostgreSQL (via Supabase)
- **Authentication:** Supabase Auth
- **Database Security:** Row Level Security (RLS)
- **Navigation:** GoRouter
- **Architecture:** Clean Architecture, Feature-First Structure, and Repository Pattern

## 🏗️ Architecture

The project follows a layered architecture to separate business logic, data access, and presentation.

- **Presentation:** Flutter UI, Cubits, and application states.
- **Domain:** Entities, repository contracts, and use cases.
- **Data:** Remote data sources, models, and repository implementations.
- **Core:** Shared configuration, dependency injection, routing, themes, utilities, and error handling.

This structure is intended to improve maintainability, testability, and scalability as new features are introduced.

## 🔐 Authentication & Security

The authentication module includes:

- Email and password registration.
- Email verification.
- Login and logout.
- Password reset requests.
- University selection during registration.
- Role-based application navigation.

Database access is designed to be protected through Supabase Row Level Security policies and appropriate authorization checks.

## 🌐 Localization & UI

- Arabic interface with RTL layout.
- Responsive design for different screen sizes.
- A consistent visual identity inspired by the FH Fatima Habib brand.
- Reusable UI components and shared theme configuration.

## 🚧 Development Status

**Status: In Development**

The authentication module and initial Supabase integration have been implemented. The remaining features are being developed incrementally, starting with authentication and access control before moving on to appointment booking, schedule management, and the administrative dashboard.

## 🎯 Project Goals

- Build a practical, maintainable booking system.
- Apply Clean Architecture and BLoC/Cubit in a real-world Flutter Web project.
- Integrate Flutter with Supabase authentication and PostgreSQL.
- Prevent conflicting bookings through reliable server-side validation.
- Provide a clear and accessible Arabic user experience.

## 👩‍💻 Developer

**Ghina Habib**  
Flutter Developer

GitHub: [@ghinah8](https://github.com/ghinah8)

---

*This project is being developed as a dedicated appointment booking and management platform for architecture tutoring sessions.*