//
//  ViewController.swift
//  FaceMeshTest
//
//  Created by 任玉乾 on 2022/1/12.
//

import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let sBtn = UIButton()
        sBtn.setTitle("swift", for: .normal)
        sBtn.addTarget(self, action: #selector(swiftTest), for: .touchUpInside)
        sBtn.frame = CGRect(x: 20, y: 100, width: 50, height: 50)
        sBtn.setTitleColor(.black, for: .normal)
        
        let ocBtn = UIButton()
        ocBtn.setTitle("oc", for: .normal)
        ocBtn.addTarget(self, action: #selector(ocTest), for: .touchUpInside)
        ocBtn.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        ocBtn.setTitleColor(.black, for: .normal)
        
        view.addSubview(sBtn)
        view.addSubview(ocBtn)
    }

    @objc
    private func swiftTest() {
        let vc = FaceMeshingSwiftViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    
    @objc
    private func ocTest() {
        let vc = FaceMeshingOCViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

