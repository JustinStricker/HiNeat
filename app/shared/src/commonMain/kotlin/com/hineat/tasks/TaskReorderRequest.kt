package com.hineat.tasks

import kotlinx.serialization.Serializable

@Serializable
data class TaskReorderRequest(val id: String, val position: Int)