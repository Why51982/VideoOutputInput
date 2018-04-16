//
//  ViewController.swift
//  VideoOutputInput
//
//  Created by Ocean on 2018/4/16.
//  Copyright © 2018年 Ocean. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    fileprivate lazy var session: AVCaptureSession = AVCaptureSession()
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var movieOutput: AVCaptureMovieFileOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化视频的输入&输出
        setupVideoInputOutput()
        
        // 初始化音频的输入&输出
        setupAudioInputOutput()
    }
    
    // 开始采集音视频
    @IBAction func startCapturing(_ sender: UIButton) {
        
        // 初始化一个预览图层
        setupPreviewLayer()
        session.startRunning()
        
        // 录制视频, 并且写入文件
        setupMovieFileOutput()
    }
    
    //停止录制
    @IBAction func stopCapturing(_ sender: UIButton) {
        session.stopRunning()
        movieOutput?.stopRecording()
        previewLayer?.removeFromSuperlayer()
    }
    
    
    @IBAction func switchCamera(_ sender: UIButton) {
        
        // 取出之前镜头的方向
        guard let videoInput = self.videoInput else { return }
        let position: AVCaptureDevice.Position = videoInput.device.position == AVCaptureDevice.Position.front ? .back : .front
        let devices = AVCaptureDevice.devices()
        guard let device = devices.filter({ $0.position == position}).first else { return
        }
        
        guard let newInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 移除之前的input, 添加新的input
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        session.commitConfiguration()
        
        // 保存最新的input
        self.videoInput = newInput
    }
}

// MARK:- 初始化方法
extension ViewController {
    // 初始化视频的输入输出
    fileprivate func setupVideoInputOutput() {
        // 添加视频的输入
        let devices = AVCaptureDevice.devices()
        guard let device = devices.filter({ $0.position == .front }).first else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        videoInput = input
        
        // 添加视频的输出
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        videoOutput = output
        
        // 添加输入输出
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
    }
    
    // 初始化音频的输入输出
    fileprivate func setupAudioInputOutput() {
        // 添加音频的输入
        guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 创建输出
        let output = AVCaptureAudioDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        
        //添加输入&输出
        session.beginConfiguration()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
    }
    
    // 初始化预览层
    fileprivate func setupPreviewLayer() {
        // 创建预览图层
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // 设置previewLayer属性
        previewLayer.frame = view.bounds
        
        // 图层添加到控制器的View的layer中
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
    
    // 录制视频, 并且写入文件
    fileprivate func setupMovieFileOutput() {
        
        if let output = movieOutput {
            session.removeOutput(output)
        }
        
        // 创建写入文件的输出
        let fileOutput = AVCaptureMovieFileOutput()
        movieOutput = fileOutput
        
        let connection = fileOutput.connection(with: .video)
        connection?.automaticallyAdjustsVideoMirroring = true
        
        session.beginConfiguration()
        if session.canAddOutput(fileOutput) {
            session.addOutput(fileOutput)
        }
        session.commitConfiguration()
        
        // 直接开始写入文件
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let fileUrl = URL(fileURLWithPath: filePath)
        fileOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
}

// MARK:- <AVCaptureVideoDataOutputSampleBufferDelegate>
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if videoOutput?.connection(with: AVMediaType.video) == connection {
            print("采集视频数据")
        } else {
            print("采集音频数据")
        }
    }
}

extension ViewController : AVCaptureFileOutputRecordingDelegate {
   
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入文件")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("完成写入文件")
    }
    
}

