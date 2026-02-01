import Foundation
import AVFoundation

@Observable
class AudioRecorderManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    enum PlaybackState {
        case stopped
        case playing
        case paused
    }
    
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var playbackState: PlaybackState = .stopped
    var currentPlayingURL: URL?
    var playbackProgress: Double = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var playbackTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
#if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
#endif
            // macOS typically handles this via system preferences, but we can check if needed.
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func requestPermission() async -> Bool {
#if os(iOS)
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
#else
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
#endif
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let filename = UUID().uuidString + ".m4a"
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docDir.appendingPathComponent(filename)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            startTimer()
            print("Started recording: \(url.lastPathComponent)")
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }
        
        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        stopTimer()
        print("Stopped recording: \(url.lastPathComponent)")
        return url
    }

    func playRecording(url: URL) {
        do {
            if playbackState == .paused && currentPlayingURL == url {
                resumePlayback()
                return
            }
            
            stopPlayback() // Stop any existing playback
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            playbackState = .playing
            currentPlayingURL = url
            startPlaybackTimer()
        } catch {
            print("Could not play audio: \(error)")
            stopPlayback()
        }
    }
    
    func pausePlayback() {
        guard playbackState == .playing else { return }
        audioPlayer?.pause()
        playbackState = .paused
        stopPlaybackTimer()
    }
    
    func resumePlayback() {
        guard playbackState == .paused else { return }
        audioPlayer?.play()
        playbackState = .playing
        startPlaybackTimer()
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackState = .stopped
        currentPlayingURL = nil
        stopPlaybackTimer()
        playbackProgress = 0.0
    }
    
    // MARK: - Playback Timer
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        playbackProgress = player.currentTime / player.duration
    }
    
    // MARK: - Timer
    private func startTimer() {
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        recordingDuration = 0
    }
    
    // MARK: - Delegates
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            // Handle failure
            isRecording = false
            stopTimer()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Playback finished
        playbackState = .stopped
        currentPlayingURL = nil
        stopPlaybackTimer()
        playbackProgress = 0.0
    }
}
