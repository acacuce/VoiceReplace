//
//  ViewController.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit
import AVFoundation
import Photos

class RecordingViewController: UIViewController{
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    private lazy var videoPreprocessor = VideoPreprocessor()
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

    private lazy var imagePickerController = UIImagePickerController()
    private lazy var contentView = RecordingView()

    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.recordButton.addTarget(self, action: #selector(toggleMovieRecording(_:)), for: .touchUpInside)
        contentView.galleryButton.addTarget(self, action: #selector(pickVideoFromLibrary(_:)), for: .touchUpInside)
        contentView.previewView.session = session
        requestAuthorization()
        sessionQueue.async {
            self.configureSession()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runSessionIfPossible()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }

        super.viewWillDisappear(animated)
    }

    /// MARK:  Action Handlers

    @objc private func toggleMovieRecording(_ recordButton: UIButton) {
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }

        let videoPreviewLayerOrientation = contentView.previewView.videoPreviewLayer.connection?.videoOrientation
        sessionQueue.async {
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }

                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!

                // Start recording video to a temporary file.
                let outputFileName = UUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                movieFileOutput.stopRecording()
            }
        }
    }

    @objc private func pickVideoFromLibrary(_ recordButton: UIButton) {
        imagePickerController.sourceType = .savedPhotosAlbum
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.movie"]
        present(imagePickerController, animated: true, completion: nil)
    }



    private func openEditor(with videoURL: URL) {
        videoPreprocessor.processVideo(at: videoURL) { result in
            switch result {
            case let .success(video):
                DispatchQueue.main.async {
                    let editViewController = EditorViewController(editingVideo: video)
                    editViewController.modalPresentationStyle = .fullScreen
                    self.present(editViewController, animated: true, completion: nil)
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.showEditError()
                }
            }
        }
    }

    private func showEditError() {
        let alertMsg = "Edit open failed"
        let message = NSLocalizedString("Unable to edit media", comment: alertMsg)
        let alertController = UIAlertController(title: "Voice Changer", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }



    // MARK: Private: Access Authorization
    private func requestAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break

        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.

             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })

        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
    }

    // MARK: Private: Session Management

    private func configureSession() {
        if setupResult != .success {
            return
        }

        session.beginConfiguration()

        session.sessionPreset = .iFrame1280x720

        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera, if available, otherwise default to a wide angle camera.

            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual wide camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput

                DispatchQueue.main.async {
                    let initialVideoOrientation: AVCaptureVideoOrientation = .portrait

                    self.contentView.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        // Add an audio input device.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }

        let movieFileOutput = AVCaptureMovieFileOutput()

        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)

            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }


                self.movieFileOutput = movieFileOutput
            }
        }

        session.commitConfiguration()
    }

    private func runSessionIfPossible() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning

            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "Voice Changer doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "Voice Changer", message: message, preferredStyle: .alert)

                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))

                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                                                            }))

                    self.present(alertController, animated: true, completion: nil)
                }

            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "Voice Changer", message: message, preferredStyle: .alert)

                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))

                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

}

extension RecordingViewController: UIImagePickerControllerDelegate ,UINavigationControllerDelegate  {
    // MARK: Image Picker


    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        openEditor(with: videoURL)
        self.dismiss(animated: true, completion: nil)
    }

}


extension RecordingViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.contentView.recordButton.isSelected = true
        }
    }

    /// - Tag: DidFinishRecording
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid

                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }

        var success = true

        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }

        if success {
            openEditor(with: outputFileURL)

        } else {
            cleanup()
        }

        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
        DispatchQueue.main.async {
            self.contentView.recordButton.isSelected = false
        }
    }

}

