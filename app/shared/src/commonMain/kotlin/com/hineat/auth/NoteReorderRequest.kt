package com.hineat.auth

import kotlinx.serialization.Serializable

@Serializable
data class NoteReorderRequest(val id: String, val position: Int)