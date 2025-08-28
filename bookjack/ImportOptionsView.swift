//
//  ImportOptionsView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI

struct ImportOptionsView: View {
    @Binding var showingFilePicker: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showingFilePicker = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from Files")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Choose audiobook files from the Files app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supported Formats")
                            .font(.headline)
                        
                        HStack {
                            ForEach(["M4B", "M4A", "MP3", "FLAC"], id: \.self) { format in
                                Text(format)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text("ZIP archives containing audiobook folders are also supported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Import Audiobooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    ImportOptionsView(showingFilePicker: .constant(false))
}
