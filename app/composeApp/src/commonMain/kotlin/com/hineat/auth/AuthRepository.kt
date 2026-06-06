package com.hineat.auth

import com.hineat.auth.LoginRequest

interface AuthRepository {
    suspend fun login(request: LoginRequest): String
    fun clearToken()
    val isLoggedIn: Boolean
}