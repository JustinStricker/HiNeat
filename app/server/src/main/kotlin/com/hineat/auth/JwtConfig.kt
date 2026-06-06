package com.hineat.auth

import java.util.*

object JwtConfig {
    const val secret = "my-super-secret-key-that-should-be-in-env-vars"
    const val issuer = "com.hineat"
    const val audience = "com.hineat"
    const val expirationMillis = 3600000L // 1 hour
}