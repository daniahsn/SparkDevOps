import SwiftUI

// MARK: - Data Model
struct Note: Identifiable, Codable {
    let id = UUID()
    let title: String
    let body: String
}

// MARK: - Main View
struct LocalStorage: View {
    @State private var notes: [Note] = []
    @State private var showingAddNote = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: { showingAddNote = true }) {
                    Label("Add Note", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding([.horizontal, .top])
                }
                
                List(notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Local Storage")
            .onAppear(perform: loadNotes)
            .sheet(isPresented: $showingAddNote) {
                AddNoteView { newNote in
                    notes.append(newNote)
                    saveNotes()
                }
            }
        }
    }
    
    // MARK: - File Storage
    private func notesFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("notes.json")
    }
    
    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: notesFileURL())
        } catch {
            print("Error saving notes:", error)
        }
    }
    
    private func loadNotes() {
        do {
            let data = try Data(contentsOf: notesFileURL())
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("No saved notes yet or failed to load:", error)
        }
    }
}

// MARK: - Add Note Sheet
struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    
    var onSave: (Note) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $text)
                    .frame(height: 150)
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newNote = Note(title: title, body: text)
                        onSave(newNote)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LocalStorage()
}
