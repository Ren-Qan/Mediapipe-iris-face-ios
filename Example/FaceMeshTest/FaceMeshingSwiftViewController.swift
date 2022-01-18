//
//  FaceMeshingSwiftViewController.swift
//  FaceMeshTest
//
//  Created by 任玉乾 on 2022/1/12.
//

import UIKit

class FaceMeshingSwiftViewController: UIViewController {
    private let KW = UIScreen.main.bounds.size.width;
    private let KH = UIScreen.main.bounds.size.height;
        
    private lazy var helper: IrisFaceMeshingHelper = {
        let helper = IrisFaceMeshingHelper()
        helper.delegate = self
        return helper
    }()
    
    private lazy var startButton: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 20, y: 100, width: 40, height: 40)
        btn.backgroundColor = .black
        btn.setTitle("start", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(start), for: .touchUpInside)
        return btn
    }()
    
    private lazy var originalImageView: UIImageView = {
        let view = UIImageView()
        let w = KW * 0.5 - 25
        view.frame = CGRect(x: 20, y: 160, width: w, height: KH * w / KW)
        view.layer.masksToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var medipipeImageView: UIImageView = {
        let view = UIImageView()
        let w = KW * 0.5 - 25
        view.frame = CGRect(x: 5 + KW * 0.5, y: 160, width: w, height: KH * w / KW)
        view.layer.masksToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(startButton)
        view.addSubview(originalImageView)
        view.addSubview(medipipeImageView)
    }

    @objc
    private func start() {
        helper.startCamera()
    }
}

extension FaceMeshingSwiftViewController: IrisFaceMeshingHelperDelegate {
    func cameraFrame(with pixelBuffer: CVPixelBuffer?) {
        if let pixelBuffer = pixelBuffer {
            let image = FaceMeshingOCViewController.convert(pixelBuffer)
            DispatchQueue.main.async {
                self.originalImageView.image = image
            }
        }
    }
    
    func mediapipeProcessedFrame(with pixelBuffer: CVPixelBuffer?) {
        if let pixelBuffer = pixelBuffer {
            let image = FaceMeshingOCViewController.convert(pixelBuffer)
            DispatchQueue.main.async {
                self.medipipeImageView.image = image
            }
        }
    }
}
