package com.hineat.auth

import com.hineat.auth.AuthService
import com.hineat.auth.LoginRequest
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Routing.authRoutes(authService: AuthService) {
    post("/login") {
        val request = call.receive<LoginRequest>()
        val token = authService.login(request)
        if (token != null) {
            call.respond(mapOf("token" to token))
        } else {
            call.respond(HttpStatusCode.Unauthorized, "Invalid credentials")
        }
    }
}