package com.hineat.tasks

import com.hineat.tasks.Task
import com.hineat.tasks.TaskReorderRequest
import kotlinx.coroutines.flow.Flow

interface TasksRepository {
    fun getAll(): Flow<List<Task>>
    suspend fun save(task: Task): Task
    suspend fun update(task: Task): Task?
    suspend fun delete(id: String)
    suspend fun reorder(updates: List<TaskReorderRequest>)
}