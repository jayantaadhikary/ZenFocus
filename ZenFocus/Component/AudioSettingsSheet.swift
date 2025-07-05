//
//  AudioSettingsSheet.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 05/07/25.
//

import SwiftUI
import AudioToolbox

struct AudioSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioManager = AmbientAudioManager.shared
    @State private var ambientVolume: Double = 0.5
    @State private var enableCompletionSound: Bool = true
    @State private var completionSoundVolume: Double = 0.8
    @State private var isTestingSound: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AmbientAudioSection(
                        ambientVolume: $ambientVolume,
                        isTestingSound: $isTestingSound,
                        audioManager: audioManager
                    )
                    
                    SessionFeedbackSection(
                        enableCompletionSound: $enableCompletionSound,
                        completionSoundVolume: $completionSoundVolume
                    )
                    
                    AdvancedSettingsSection()
                }
                .padding()
            }
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAudioSettings()
        }
        .onDisappear {
            saveAudioSettings()
            if isTestingSound {
                audioManager.stop()
                isTestingSound = false
            }
        }
    }
    
    private func loadAudioSettings() {
        let savedAmbientVolume = UserDefaults.standard.float(forKey: "ambientVolume")
        ambientVolume = savedAmbientVolume > 0 ? Double(savedAmbientVolume) : 0.5
        
        enableCompletionSound = UserDefaults.standard.object(forKey: "enableCompletionSound") as? Bool ?? true
        
        let savedCompletionVolume = UserDefaults.standard.float(forKey: "completionSoundVolume")
        completionSoundVolume = savedCompletionVolume > 0 ? Double(savedCompletionVolume) : 0.8
        
        audioManager.setVolume(Float(ambientVolume))
    }
    
    private func saveAudioSettings() {
        UserDefaults.standard.set(Float(ambientVolume), forKey: "ambientVolume")
        UserDefaults.standard.set(enableCompletionSound, forKey: "enableCompletionSound")
        UserDefaults.standard.set(Float(completionSoundVolume), forKey: "completionSoundVolume")
    }
}

// MARK: - Component Views
struct AmbientAudioSection: View {
    @Binding var ambientVolume: Double
    @Binding var isTestingSound: Bool
    let audioManager: AmbientAudioManager
    
    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                VolumeSlider(volume: $ambientVolume, audioManager: audioManager)
                TestSoundButton(isTestingSound: $isTestingSound, audioManager: audioManager)
            }
            .padding(.vertical, 8)
        } label: {
            Label("Ambient Audio", systemImage: "speaker.wave.2")
        }
    }
}

struct VolumeSlider: View {
    @Binding var volume: Double
    let audioManager: AmbientAudioManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Volume")
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Slider(value: $volume, in: 0...1, step: 0.1)
                .tint(.accentColor)
                .onChange(of: volume) { _, newValue in
                    audioManager.setVolume(Float(newValue))
                }
        }
    }
}

struct TestSoundButton: View {
    @Binding var isTestingSound: Bool
    let audioManager: AmbientAudioManager
    
    var body: some View {
        Button(action: testSoundAction) {
            HStack {
                Image(systemName: isTestingSound ? "stop.fill" : "play.fill")
                Text(isTestingSound ? "Stop Test" : "Test Rain Sound")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .foregroundStyle(.primary)
    }
    
    private func testSoundAction() {
        if isTestingSound {
            audioManager.stop()
            isTestingSound = false
        } else {
            audioManager.playSound(named: "rain.mp3")
            isTestingSound = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                audioManager.stop()
                isTestingSound = false
            }
        }
    }
}

struct SessionFeedbackSection: View {
    @Binding var enableCompletionSound: Bool
    @Binding var completionSoundVolume: Double
    
    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                Toggle("Completion Sound", isOn: $enableCompletionSound)
                
                if enableCompletionSound {
                    CompletionSoundControls(completionSoundVolume: $completionSoundVolume)
                }
            }
            .padding(.vertical, 8)
        } label: {
            Label("Session Feedback", systemImage: "bell")
        }
    }
}

struct CompletionSoundControls: View {
    @Binding var completionSoundVolume: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Sound Volume")
                Spacer()
                Text("\(Int(completionSoundVolume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Slider(value: $completionSoundVolume, in: 0...1, step: 0.1)
                .tint(.accentColor)
            
            Button(action: {
                AudioServicesPlaySystemSound(1106)
            }) {
                HStack {
                    Image(systemName: "speaker.2")
                    Text("Test Completion Sound")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .foregroundStyle(.blue)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: completionSoundVolume)
    }
}

struct AdvancedSettingsSection: View {
    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mix with Other Apps")
                            .font(.subheadline)
                        Text("Allow music to play alongside ambient sounds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .disabled(true)
                }
                
                Text("Advanced audio settings available in ZenFocus Pro")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.vertical, 8)
        } label: {
            Label("Advanced", systemImage: "gearshape")
        }
    }
}

#Preview {
    AudioSettingsSheet()
}
