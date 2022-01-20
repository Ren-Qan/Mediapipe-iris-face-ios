//
//  APIViewController.swift
//  FaceMeshTest
//
//  Created by 任玉乾 on 2022/1/20.
//

import UIKit

class APIViewController: FaceMeshingSwiftViewController {
    private lazy var originalLeftEyeBorder: UIView = borderView(.blue)
    private lazy var originalRightEyeBorder: UIView = borderView(.blue)
    private lazy var originalFaceBorder: UIView = borderView(.red)
    
    private lazy var mediaPipeLeftEyeBorder: UIView = borderView(.blue)
    private lazy var mediaPipeRightEyeBorder: UIView = borderView(.blue)
    private lazy var mediaPipeFaceBorder: UIView = borderView(.red)
    
    private lazy var lastScoreLab: UILabel = {
        let lab = UILabel()
        lab.textAlignment = .center
        lab.frame = CGRect(x: 0,
                           y: self.medipipeImageView.frame.maxY + 10,
                           width: self.KW,
                           height: 50)
        lab.numberOfLines = 0
        return lab
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalImageView.addSubview(originalLeftEyeBorder)
        originalImageView.addSubview(originalRightEyeBorder)
        originalImageView.addSubview(originalFaceBorder)
        
        medipipeImageView.addSubview(mediaPipeLeftEyeBorder)
        medipipeImageView.addSubview(mediaPipeRightEyeBorder)
        medipipeImageView.addSubview(mediaPipeFaceBorder)
        
        view.addSubview(lastScoreLab)
        
        let lab = UILabel()
        lab.text = "面部可信度, 只会在需要面部检测的时候返回"
        lab.textAlignment = .center
        lab.textColor = .black
        lab.frame = CGRect(x: 0, y: KH - 80, width: KW, height: 20)
        view.addSubview(lab)
    }
    
    private func borderView(_ color: UIColor) -> UIView {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = color.cgColor
        return view
    }
    
    func didReceiveFaceNormalizedRect(_ faceRect: NormalizedRectModel?) {
        guard let faceRect = faceRect else {
            return
        }
        DispatchQueue.main.async {
            self.originalFaceBorder.frame = faceRect.convert(withFrame: self.originalImageView.bounds,
                                                             scale: 0.5)
            self.mediaPipeFaceBorder.frame = faceRect.convert(withFrame: self.medipipeImageView.bounds,
                                                              scale: 0.5)
        }
    }
    
    func didReceiveLeftEyeRect(_ eyeRect: NormalizedRectModel?) {
        guard let eyeRect = eyeRect else {
            return
        }
        DispatchQueue.main.async {
            self.originalLeftEyeBorder.frame = eyeRect.convert(withFrame: self.originalImageView.bounds,
                                                               scale: 0.5)
            self.mediaPipeLeftEyeBorder.frame = eyeRect.convert(withFrame: self.medipipeImageView.bounds,
                                                                scale: 0.5)
        }
    }
    
    func didReceiveRightEyeRect(_ eyeRect: NormalizedRectModel?) {
        guard let eyeRect = eyeRect else {
            return
        }
        
        DispatchQueue.main.async {
            self.originalRightEyeBorder.frame = eyeRect.convert(withFrame: self.originalImageView.bounds,
                                                                scale: 0.5)
            self.mediaPipeRightEyeBorder.frame = eyeRect.convert(withFrame: self.medipipeImageView.bounds,
                                                                 scale: 0.5)
        }
    }
    
    func didReceiveFeceDecetionScore(_ score: NSNumber?) {
        guard let score = score?.floatValue else {
            return
        }
//        print("face scroe: \(score)")
        DispatchQueue.main.async {
            let lab = UILabel()
            lab.frame.origin.x = CGFloat.random(in: 0 ..< self.KW - 100)
            lab.frame.origin.y = self.KH - 100 - CGFloat.random(in: 0 ..< 50)
            lab.text = "\(score)"
            lab.frame.size = CGSize(width: 100, height: 20)
            lab.textColor = .randomColor
            self.view.addSubview(lab)
            
            self.lastScoreLab.textColor = lab.textColor
            self.lastScoreLab.text = "last face detection score:\n\(score)"
            
            UIView.animate(withDuration: 1) {
                lab.center.y -= CGFloat.random(in: 40 ..< 100)
                lab.alpha = 0
            } completion: { _ in
                lab.removeFromSuperview()
            }
        }
    }
}


extension UIColor {
    class var randomColor: UIColor {
        get {
            let red = CGFloat(arc4random() % 256) / 255.0
            let green = CGFloat(arc4random() % 256) / 255.0
            let blue = CGFloat(arc4random() % 256) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}
