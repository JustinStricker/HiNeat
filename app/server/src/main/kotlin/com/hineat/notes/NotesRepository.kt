package com.hineat.notes

import com.hineat.auth.NoteReorderRequest
import com.hineat.core.Visibility
import com.hineat.notes.Note

interface NotesRepository {
    fun getAll(): List<Note>
    fun getByOwner(ownerId: String, visibility: Visibility? = null): List<Note>
    fun getPublicPosts(limit: Int = 20, offset: Int = 0): List<Note>
    fun countPublicPosts(): Long
    fun save(note: Note): Note
    fun update(note: Note): Note?
    fun delete(id: String): Boolean
    fun deleteAllByOwner(ownerId: String): Int
    fun deleteAll(): Int
    fun reorder(updates: List<NoteReorderRequest>)
    fun toggleTask(id: String, lineIndex: Int): Note?
}
