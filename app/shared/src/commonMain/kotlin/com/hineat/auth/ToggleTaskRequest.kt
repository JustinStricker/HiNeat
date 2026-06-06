package com.hineat.auth

import kotlinx.serialization.Serializable

@Serializable
data class ToggleTaskRequest(val lineIndex: Int)