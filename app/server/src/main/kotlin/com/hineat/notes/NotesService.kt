package com.hineat.notes

import com.hineat.auth.NoteReorderRequest
import com.hineat.core.Visibility
import com.hineat.notes.Note
import com.hineat.notes.NotesRepository

class NotesService(private val repository: NotesRepository) {
    fun getNotes(): List<Note> = repository.getAll().sortedBy { it.position }

    fun getNotesByOwner(ownerId: String, visibility: Visibility? = null): List<Note> =
        repository.getByOwner(ownerId, visibility).sortedBy { it.position }

    fun getPublicPosts(limit: Int = 20, offset: Int = 0): List<Note> =
        repository.getPublicPosts(limit, offset)

    fun countPublicPosts(): Long = repository.countPublicPosts()

    fun createNote(note: Note): Note = repository.save(note)

    fun updateNote(note: Note): Note? = repository.update(note)

    fun deleteNote(id: String): Boolean = repository.delete(id)

    fun deleteAllNotes(ownerId: String): Int = repository.deleteAllByOwner(ownerId)

    fun deleteAll(): Int = repository.deleteAll()

    fun reorderNotes(updates: List<NoteReorderRequest>) = repository.reorder(updates)

    fun toggleTask(id: String, lineIndex: Int): Note? = repository.toggleTask(id, lineIndex)
}